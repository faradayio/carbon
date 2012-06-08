require 'celluloid'

module Carbon
  class QueryPool
    include Celluloid

    def process(query)
      query.result
    end
  end
end
