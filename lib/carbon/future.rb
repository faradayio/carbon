require 'uri'
require 'net/http'
require 'cache_method'
require 'hashie/mash'
require 'multi_json'

module Carbon
  # @private
  class Future
    class << self
      def single(future)
        uri = ::URI.parse("#{Carbon::DOMAIN}/#{future.emitter.underscore.pluralize}.json")
        raw_result = ::Net::HTTP.post_form(uri, future.params)
        result = ::Hashie::Mash.new
        case raw_result
        when ::Net::HTTPSuccess
          result.status = raw_result.code.to_i
          result.success = true
          result.merge! ::MultiJson.decode(raw_result.body)
        else
          result.status = raw_result.code.to_i
          result.success = false
          result.errors = [raw_result.body]
        end
        result
      end

      def multi(futures)
        uniq_pending_futures = futures.uniq.select do |future|
          future.pending?
        end
        return futures if uniq_pending_futures.empty?
        require 'em-http-request'
        multi = ::EventMachine::MultiRequest.new
        ::EventMachine.run do
          uniq_pending_futures.each do |future|
            multi.add future, ::EventMachine::HttpRequest.new(Carbon::DOMAIN).post(:path => "/#{future.emitter.underscore.pluralize}.json", :body => future.params)
          end
          multi.callback do
            multi.responses[:callback].each do |future, http|
              result = ::Hashie::Mash.new
              result.status = http.response_header.status
              if (200..299).include?(result.status)
                result.success = true
                result.merge! ::MultiJson.decode(http.response)
              else
                result.success = false
                result.errors = [http.response]
              end
              future.result = result
            end
            multi.responses[:errback].each do |future, http|
              result = ::Hashie::Mash.new
              result.status = http.response_header.status
              result.success = false
              result.errors = ['Timeout or other network error.']
              future.result = result
            end
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

    def result=(result)
      @result = result
      self.result # force this to be cached
    end

    def result
      if @result
        @result
      elsif not multi?
        @result = Future.single(self)
      end
    end
    cache_method :result

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
