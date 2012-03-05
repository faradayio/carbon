require 'singleton'
require 'logger'
require 'httpclient'
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
      raw_response = ::HTTPClient.post("http://#{domain}/#{emitter.underscore.pluralize}.json", characteristics.merge(:key => config[:key]))
      if (200..299).include?(raw_response.status)
        response = ::Hashie::Mash.new ::MultiJson.decode(raw_response.body)
        response.status = raw_response.status
        response.success = true
      else
        response = ::Hashie::Mash.new
        response.status = raw_response.status
        response.success = false
        response.errors = [raw_response.body]
      end
      response
    rescue ::Exception
      response = ::Hashie::Mash.new
      response.status = 500
      response.success = false
      response.errors = [$!]
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
      config.fetch(:domain, DEFAULT_DOMAIN)
    end

    def self.threads
      config.fetch(:domain, DEFAULT_THREADS)
    end
  end
end

BrighterPlanetApi = BrighterPlanet::Api
