require 'net/http'
require 'hashie/mash'
require 'multi_json'
require 'active_support/core_ext'

require 'carbon/registry'

module Carbon
  DOMAIN = 'http://impact.brighterplanet.com'

  @@key = nil unless defined?(@@key)

  # Set the Brighter Planet API key that you can get from http://keys.brighterplanet.com
  def self.key=(key)
    @@key = key
  end

  # Get the key you've set.
  def self.key
    @@key
  end

  # Do a simple query.
  #
  # @param [String] emitter The emitter name, like "AutomobileTrip" or "Flight"
  # @param [Hash] params Valid keys are like :origin_airport => 'jfk' and :timeframe => Timeframe.new(:year => 2009) and :comply => [:ghg_protocol_scope_3]
  def self.query(emitter, params = {})
    params ||= {}
    params = params.reverse_merge(:key => key) if key
    uri = ::URI.parse("#{DOMAIN}/#{emitter.underscore.pluralize}.json")
    raw_response = ::Net::HTTP.post_form(uri, params)
    response = ::Hashie::Mash.new
    case raw_response
    when ::Net::HTTPSuccess
      response.status = raw_response.code.to_i
      response.success = true
      response.merge! ::MultiJson.decode(raw_response.body)
    else
      response.status = raw_response.code.to_i
      response.success = false
      response.error_body = raw_response.respond_to?(:body) ? raw_response.body : ''
      response.errors = [raw_response.class.name]
    end
    response
  end

  # Where each query is [emitter, params]
  #
  # @param [Array] queries An array of arrays like [ 'Flight', { :origin_airport => 'JFK', :timeframe => 2009 } ]
  def self.multi(queries)
    require 'em-http-request'
    unsorted = {}
    multi = ::EventMachine::MultiRequest.new
    ::EventMachine.run do
      queries.each_with_index do |(emitter, params), query_idx|
        params ||= {}
        params = params.reverse_merge(:key => key) if key
        multi.add query_idx, ::EventMachine::HttpRequest.new(DOMAIN).post(:path => "/#{emitter.underscore.pluralize}.json", :body => params)
      end
      multi.callback do
        multi.responses[:callback].each do |query_idx, http|
          response = ::Hashie::Mash.new
          response.status = http.response_header.status
          if (200..299).include?(response.status)
            response.success = true
            response.merge! ::MultiJson.decode(http.response)
          else
            response.success = false
            response.errors = [http.response]
          end
          unsorted[query_idx] = response
        end
        multi.responses[:errback].each do |query_idx, http|
          response = ::Hashie::Mash.new
          response.status = http.response_header.status
          response.success = false
          response.errors = ['Timeout or other network error.']
          unsorted[query_idx] = response
        end
        ::EventMachine.stop
      end
    end
    unsorted.sort_by do |query_idx, _|
      query_idx
    end.map do |_, response|
      response
    end
  end

  # Called when you `include Carbon` and adds the class method `emit_as`.
  def self.included(klass)
    klass.extend ClassMethods
  end

  # Mixed into any class that includes `Carbon`.
  module ClassMethods
    def emit_as(emitter, &blk)
      emitter = emitter.to_s.singularize.camelcase
      registrar = Registry::Registrar.new self, emitter
      registrar.instance_eval(&blk)
    end
  end

  # What will be sent to Brighter Planet CM1.
  def impact_params
    return unless registration = Registry.instance[self.class.name]
    registration.characteristics.inject({}) do |memo, (method_id, translation_options)|
      k = translation_options.has_key?(:as) ? translation_options[:as] : method_id
      if translation_options.has_key?(:key)
        k = "#{k}[#{translation_options[:key]}]"
      end
      v = send(method_id)
      memo[k] = v
      memo
    end
  end

  # Get an impact estimate from Brighter Planet CM1.
  #
  # @param [Hash] options The options hash. Valid keys are :timeframe and :comply.
  def impact(extra_params = {})
    return unless registration = Registry.instance[self.class.name]
    Carbon.query registration.emitter, impact_params.merge(extra_params)
  end
end
