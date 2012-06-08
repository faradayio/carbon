require 'celluloid'

module Carbon
  class QueryPool
    include Celluloid

    def perform(query)
      query.result
    end
  end
end
