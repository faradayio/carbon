One way to reduce the number of connections by a constant... but it makes it slower (because requests are serialized) and less reliable (because there is a 30s heroku limit)

    def self.multi(queries)
      unsorted = {}
      pool_size = (queries.length.to_f / 3).ceil
      $stderr.puts "Starting #{pool_size} workers"
      ::EventMachine.run do
        multi = ::EventMachine::MultiRequest.new
        pool = 0.upto(pool_size).map do
          ::EventMachine::HttpRequest.new("http://#{domain}")
        end
        pool_idx = 0
        queries.each_with_index do |(emitter, params), query_idx|
          params ||= {}
          multi.add query_idx, pool[pool_idx].post(:path => "/#{emitter.underscore.pluralize}.json", :body => params, :keepalive => true)
          pool_idx = (pool_idx + 1) % pool_size
        end
        multi.callback do
          multi.responses[:callback].each do |query_idx, http|
            result = ::Hashie::Mash.new
            result.status = http.response_header.status
            if (200..299).include?(result.status)
              result.success = true
              result.merge! ::MultiJson.decode(http.response)
            else
              result.success = false
              result.errors = [http.response]
            end
            unsorted[query_idx] = result
          end
          multi.responses[:errback].each do |query_idx, http|
            result = ::Hashie::Mash.new
            result.status = http.response_header.status
            result.success = false
            result.errors = ['Timeout or other network error.']
            unsorted[query_idx] = result
          end
          ::EventMachine.stop
        end
      end
      unsorted.sort_by do |query_idx, _|
        query_idx
      end.map do |_, result|
        result
      end
    end
