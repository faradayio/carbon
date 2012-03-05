require 'singleton'
require 'logger'
require 'faraday'
require 'active_support/core_ext'
require 'hashie/mash'
require 'multi_json'
require 'concur'
# require 'brighter_planet_metadata'

module BrighterPlanet
  module Api
    DEFAULT_DOMAIN = 'impact.brighterplanet.com'
    DEFAULT_THREADS = 10

    def self.query(emitter, characteristics = {})
      characteristics ||= {}
      # raise ::ArgumentError, %{Emitter "#{emitter}" not recognized} unless BrighterPlanet.metadata.emitters.include?(emitter)
      conn = ::Faraday.new(:url => domain) do |builder|
        builder.request :url_encoded
        builder.adapter :net_http
      end
      raw_response = conn.post do |req|
        req.url "/#{emitter.underscore.pluralize}.json"
        req.params = characteristics.merge(:key => config[:key])
      end
      response = ::Hashie::Mash.new ::MultiJson.decode(raw_response.body)
      response.success = true
      response
    rescue ::Exception
      response = ::Hashie::Mash.new
      response.success = false
      response.errors = $!
      response
    end

    # Where each query is [emitter, characteristics]
    def self.multi(queries)
      ::Concur.logger = logger
      executor = ::Concur::Executor.new_thread_pool_executor(threads)
      queries.map do |emitter, characteristics|
        executor.execute do
          query emitter, characteristics
        end
      end.map do |future|
        future.get
      end
    end

    class Config < ::Hash; include ::Singleton; end
    def self.config
      Config.instance
    end

    def self.logger
      unless config.has_key?(:logger)
        default_logger = ::Logger.new($stderr)
        default_logger.level = ::Logger::INFO
        config[:logger] = default_logger
      end
      config[:logger]
    end

    def self.domain
      'http://' + config.fetch(:domain, DEFAULT_DOMAIN)
    end

    def self.threads
      config.fetch(:domain, DEFAULT_THREADS)
    end
  end
end

BrighterPlanetApi = BrighterPlanet::Api
