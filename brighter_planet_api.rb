require 'singleton'
require 'em-http-request'
require 'hashie/mash'
require 'multi_json'
require 'active_support/core_ext'
# require 'brighter_planet_metadata'

module BrighterPlanet
  module Api
    DEFAULT_DOMAIN = 'impact.brighterplanet.com'
    
    def self.query(emitter, characteristics = {})
      characteristics ||= {}
      characteristics = characteristics.merge(:key => config[:key])
      response = ::Hashie::Mash.new
      ::EventMachine.run do
        http = ::EventMachine::HttpRequest.new("http://#{domain}").post :path => "/#{emitter.underscore.pluralize}.json", :body => characteristics
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

    # Where each query is [emitter, characteristics]
    def self.multi(queries)
      unsorted = {}
      multi = ::EventMachine::MultiRequest.new
      ::EventMachine.run do
        queries.each_with_index do |(emitter, characteristics), query_idx|
          characteristics ||= {}
          characteristics = characteristics.merge(:key => config[:key])
          multi.add query_idx, ::EventMachine::HttpRequest.new("http://#{domain}").post(:path => "/#{emitter.underscore.pluralize}.json", :body => characteristics)
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

    class Config < ::Hash; include ::Singleton; end
    def self.config
      Config.instance
    end

    def self.domain
      config.fetch(:domain, DEFAULT_DOMAIN)
    end
  end
end

BrighterPlanetApi = BrighterPlanet::Api
