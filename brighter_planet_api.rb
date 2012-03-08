require 'singleton'
require 'em-http-request'
require 'hashie/mash'
require 'multi_json'
require 'active_support/core_ext'

module BrighterPlanetApi
  DOMAIN = 'http://impact.brighterplanet.com'

  def self.query(emitter, params = {})
    params ||= {}
    params = params.merge(:key => config[:key]) if config.has_key?(:key)
    response = ::Hashie::Mash.new
    ::EventMachine.run do
      http = ::EventMachine::HttpRequest.new(DOMAIN).post :path => "/#{emitter.underscore.pluralize}.json", :body => params
      http.errback do
        response.status = http.response_header.status
        response.success = false
        response.errors = ['Timeout or other network error.']
        ::EventMachine.stop
      end
      http.callback do
        response.status = http.response_header.status
        if (200..299).include?(response.status)
          response.success = true
          response.merge! ::MultiJson.decode(http.response)
        else
          response.success = false
          response.errors = [http.response]
        end
        ::EventMachine.stop
      end
    end
    response
  end

  # Where each query is [emitter, params]
  def self.multi(queries)
    unsorted = {}
    multi = ::EventMachine::MultiRequest.new
    ::EventMachine.run do
      queries.each_with_index do |(emitter, params), query_idx|
        params ||= {}
        params = params.merge(:key => config[:key]) if config.has_key?(:key)
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

  def self.impacts(enumerable)
    queries = enumerable.map do |instance|
      [ Registry.instance[instance.class.name].emitter, instance.impact_params ]
    end
    multi queries
  end

  class Config < ::Hash
    include ::Singleton
  end
  def self.config
    Config.instance
  end

  class Registry < ::Hash
    include ::Singleton
  end

  class Registration < ::Struct.new(:emitter, :options)
  end

  class Aspirant
    def initialize(klass, emitter)
      @klass = klass
      Registry.instance[klass.name] ||= Registration.new
      Registry.instance[klass.name].emitter = emitter
      Registry.instance[klass.name].options ||= {}
    end
    def provide(param, options = {})
      Registry.instance[@klass.name].options[param] = options
    end
  end

  module ClassMethods
    def emit_as(emitter, &blk)
      emitter = emitter.to_s.camelcase
      if existing_registration = Registry.instance[name] and existing_registration.emitter != emitter
        raise ::RuntimeError, "[brighter_planet_api] Can't register #{name} to emit as #{emitter}, already emitting as #{existing_registration.emitter}"
      end
      aspirant = Aspirant.new self, emitter
      aspirant.instance_eval(&blk)
    end
  end

  def self.included(klass)
    klass.extend ClassMethods
  end

  # What will be sent to BP
  def impact_params
    return unless registration = Registry.instance[self.class.name]
    registration.options.inject({}) do |memo, (param, options)|
      k = options.has_key?(:as) ? options[:as] : param
      if options.has_key?(:key)
        k = "#{k}[#{options[:key]}]"
      end
      v = send(param)
      memo[k] = v
      memo
    end
  end

  # The API response
  def impact
    return unless registration = Registry.instance[self.class.name]
    BrighterPlanetApi.query registration.emitter, impact_params
  end
end
