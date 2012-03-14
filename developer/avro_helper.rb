require 'hashie/mash'
require 'avro'
require 'multi_json'
require 'active_support/core_ext'

module AvroHelper
  SCALAR = ['boolean', 'int', 'float', 'string' ]
  OPTIONAL_SCALAR = SCALAR + [ 'null' ]
  OPTIONAL_STRING = ['string', 'null']
  
  def AvroHelper.api_paths(schema, parents = nil, last_type = nil, &blk)
    return unless schema.is_a?(::Hash)
    
    schema = ::Hashie::Mash.new(schema) unless schema.is_a?(::Hashie::Mash)

    my_name = schema.name

    my_type = if schema.type == 'record'
      my_schema = schema
      schema.type
    elsif schema.type.is_a?(::Hash)
      my_schema = schema.type
      schema.type.type
    end

    nested_schemas = if my_schema
      case my_type
      when 'array'
        my_schema.items
      when 'map'
        my_schema.values
      when 'record'
        my_schema.fields
      end
    end
    nested_schemas = Array.wrap nested_schemas

    # if the last type was enumerable, then i'm anonymous
    me = case last_type
    when 'array'
      '[]'
    when 'map'
      '{}'
    when NilClass
      nil
    else
      my_name
    end

    nested_schemas.each { |x| api_paths(x, [parents, me].flatten.compact, my_type, &blk) }

    # don't try to print the top leve which will be 'v2' depending on the api version number
    return unless parents

    if my_name.present? and nested_schemas.none? { |x| x.is_a?(::Hash) }
      children = case my_type
      when 'array'
        '[]'
      when 'map'
        '{}'
      end
      blk.call [parents, me, children].flatten.compact.join('.')
    end
  end

  def AvroHelper.recursively_stringify_keys(hash)
    hash.inject({}) do |result, (key, value)|
      new_key   = case key
                  when ::Symbol then key.to_s
                  else key
                  end
      new_value = case value
                  when ::Hash then recursively_stringify_keys(value)
                  when ::Array then value.map { |i| i.is_a?(::Hash) ? recursively_stringify_keys(i) : i }
                  else value
                  end
      result[new_key] = new_value
      result
    end
  end
end
