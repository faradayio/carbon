require 'uri'
require 'net/http'
require 'multi_json'
require 'hashie/mash'
require 'cache_method'

module Carbon
  # @private
  class Query
    def Query.pool
      @pool || Thread.exclusive do
        @pool ||= QueryPool.pool(:size => CONCURRENCY)
      end
    end

    def Query.perform(*args)
      case method_signature(*args)
      when :plain_query, :obj
        new(*args).result
      when :array
        queries = args.first.map do |plain_query_or_obj|
          query = new(*plain_query_or_obj)
          pool.perform! query
          query
        end
        ticks = 0
        begin
          sleep(0.1*(2**ticks)) # exponential wait
          ticks += 1
        end until queries.all? { |query| query.done? }
        queries.inject({}) do |memo, query|
          memo[query.object] = query.result
          memo
        end
      else
        raise ::ArgumentError, "You must pass one plain query, or one object that responds to #as_impact_query, or an array of such objects. Please check the docs!"
      end
    end

    # Determine if a variable is a +[emitter, param]+ style "query"
    # @private
    def Query.is_plain_query?(query)
      return false unless query.is_a?(Array)
      return false unless query.first.is_a?(String) or query.first.is_a?(Symbol)
      return true if query.length == 1
      return true if query.length == 2 and query.last.is_a?(Hash)
      false
    end

    # Determine what method signature/overloading/calling style is being used
    # @private
    def Query.method_signature(*args)
      first_arg = args.first
      case args.length
      when 1
        if is_plain_query?(args)
          # query('Flight')
          :plain_query
        elsif first_arg.respond_to?(:as_impact_query)
          # query(my_flight)
          :obj
        elsif first_arg.is_a?(::Array) and first_arg.all? { |obj| obj.respond_to?(:as_impact_query) or is_plain_query?(obj) }
          # query([my_flight, my_flight])
          :array
        end
      when 2
        if is_plain_query?(args)
          # query('Flight', :origin_airport => 'LAX')
          :plain_query
        end
      end
    end

    attr_reader :emitter
    attr_reader :params
    attr_reader :domain
    attr_reader :uri
    attr_reader :object

    def initialize(*args)
      case Query.method_signature(*args)
      when :plain_query
        @object = args
        @emitter, @params = *args
      when :obj
        @object = args.first
        @emitter, @params = *object.as_impact_query
      else
        raise ArgumentError, "Carbon::Query.new must be called with a plain query or an object that responds to #as_impact_query"
      end
      @params ||= {}
      @domain = params.delete(:domain) || Carbon.domain
      if Carbon.key and not params.has_key?(:key)
        params[:key] = Carbon.key
      end
      @uri = URI.parse("#{domain}/#{emitter.underscore.pluralize}.json")
    end

    def done?
      not @result.nil? or cache_method_cached?(:result)
    end

    def result(extra_params = {})
      @result ||= get_result(extra_params)
    end
    cache_method :result, 3_600 # one hour

    def as_cache_key
      [ @domain, @emitter, @params ]
    end

    def hash
      as_cache_key.hash
    end

    def eql?(other)
      as_cache_key == other.as_cache_key
    end
    alias :== :eql?

    private

    def get_result(extra_params = {})
      raw = Net::HTTP.post_form uri, params.merge(extra_params)
      code = raw.code.to_i
      body = raw.body
      memo = Hashie::Mash.new
      memo.code = code
      case code
      when (200..299)
        memo.success = true
        memo.merge! MultiJson.load(body)
      else
        memo.success = false
        memo.errors = [body]
      end
      memo
    end
  end
end
