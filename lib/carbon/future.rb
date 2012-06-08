require 'uri'
require 'net/http'
require 'cache_method'
require 'hashie/mash'
require 'multi_json'
require 'celluloid'

module Carbon
  class Future
    class << self
      def wrap(plain_query_or_o)
        future = if plain_query_or_o.is_a?(::Array)
          new(*plain_query_or_o)
        else
          new(*plain_query_or_o.as_impact_query)
        end
        future.object = plain_query_or_o
        future
      end

      def multi(futures)
        multi_pool = self.pool(:size => Carbon.concurrency)
        futures.uniq.map do |future|
          multi_pool.single!(future)
        end
      end
    end
  end
end
