require 'uri'
require 'net/http'
require 'multi_json'
require 'hashie/mash'
require 'cache_method'

module Carbon
  class Query
    def Query.pool
      @pool || Thread.exclusive do
        @pool ||= QueryPool.pool(:size => CONCURRENCY)
      end
    end

    def Query.make(*args)
      case method_signature(*args)
      when :plain_query
        params = args[1] || {}
        [new(args.first, params, args)]
      when :obj
        obj = args.first
        new_args = obj.as_impact_query
        new_args << obj
        [new(*new_args)]
      when :array
        args.first.map do |obj|
          make(*obj)
        end.flatten
      else
        raise ::ArgumentError, "You must pass one plain query, or one object that responds to #as_impact_query, or an array of such objects. Please check the docs!"
      end
    end

    def Query.execute(*args)
      queries = make(*args)

      if queries.length == 1
        queries.first.result
      else
        queries.inject({}) do |hsh, query|
          hsh[query.method_signature] = pool.future(:process, query).value
          hsh
        end
      end
    end

    # Determine if a variable is a +[emitter, param]+ style "query"
    # @private
    def Query.is_plain_query?(query)
      return false unless query.is_a?(::Array)
      return false unless query.first.is_a?(::String) or query.first.is_a?(::Symbol)
      return true if query.length == 1
      return true if query.length == 2 and query.last.is_a?(::Hash)
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
    attr_reader :method_signature

    attr_accessor :object

    def initialize(emitter, params = {}, method_signature = nil)
      @result = nil
      @emitter = emitter
      params = params.dup || {}
      @domain = params.delete(:domain) || Carbon.domain
      if Carbon.key and not params.has_key?(:key)
        params[:key] = Carbon.key
      end
      @params = params
      @method_signature = method_signature
    end

    def finalize(code, body = nil)
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

    def uri
      @uri ||= URI.parse("#{domain}/#{emitter.underscore.pluralize}.json")
    end

    def result(extra_params = {})
      raw_result = Net::HTTP.post_form(uri, params.merge(extra_params))
      finalize raw_result.code.to_i, raw_result.body
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
  end
end
