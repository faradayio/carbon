require 'uri'
require 'net/http'
require 'cache_method'
require 'hashie/mash'
require 'multi_json'
require 'em-http-request'

module Carbon
  # @private
  class Future
    class << self
      def wrap(query_array_or_o)
        if query_array_or_o.is_a?(::Array)
          new(*query_array_or_o)
        else
          new(*query_array_or_o.as_impact_query)
        end
      end

      def single(future)
        uri = ::URI.parse("#{Carbon::DOMAIN}/#{future.emitter.underscore.pluralize}.json")
        raw_result = ::Net::HTTP.post_form(uri, future.params)
        future.finalize raw_result.code.to_i, raw_result.body
        future
      end

      def multi(futures)
        uniq_pending_futures = futures.uniq.select { |future| future.pending? }
        return futures if uniq_pending_futures.empty?
        pool_size = [Carbon::CONCURRENCY, uniq_pending_futures.length].min
        multi = ::EventMachine::MultiRequest.new
        pool = (0..(pool_size-1)).map { ::EventMachine::HttpRequest.new(Carbon::DOMAIN) }
        pool_idx = 0
        ::EventMachine.run do
          uniq_pending_futures.each do |future|
            multi.add future, pool[pool_idx].post(:path => "/#{future.emitter.underscore.pluralize}.json", :body => future.params)
            pool_idx = (pool_idx + 1) % pool_size
          end
          multi.callback do
            multi.responses[:callback].each { |future, http| future.finalize http.response_header.status, http.response }
            multi.responses[:errback].each  { |future, http| future.finalize http.response_header.status }
            ::EventMachine.stop
          end
        end
        futures
      end
    end

    attr_reader :emitter
    attr_reader :params

    def initialize(emitter, params = {})
      @result = nil
      @emitter = emitter
      params = params || {}
      params.reverse_merge(:key => Carbon.key) if Carbon.key
      @params = params
    end

    def multi!
      @multi = true
    end

    def multi?
      @multi == true
    end

    def pending?
      @result.nil? and !cache_method_cached?(:result)
    end

    def finalize(code, body = nil)
      memo = ::Hashie::Mash.new
      memo.code = code
      case code
      when (200..299)
        memo.success = true
        memo.merge! ::MultiJson.decode(body)
      else
        memo.success = false
        memo.errors = [body]
      end
      @result = memo
      self.result # make sure it gets cached
    end

    def result
      if @result
        @result
      elsif not multi?
        Future.single self
        @result
      end
    end
    cache_method :result, 3_600 # one hour

    def as_cache_key
      [ @emitter, @params ]
    end

    def hash
      as_cache_key.hash
    end

    def eql?(other)
      as_cache_key == other.as_cache_key
    end
    alias :== :eql?
  end
end
