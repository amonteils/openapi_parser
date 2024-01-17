require_relative 'schema_validator/options'
require_relative 'schema_validator/enumable'
require_relative 'schema_validator/minimum_maximum'
require_relative 'schema_validator/base'
require_relative 'schema_validator/string_validator'
require_relative 'schema_validator/integer_validator'
require_relative 'schema_validator/float_validator'
require_relative 'schema_validator/boolean_validator'
require_relative 'schema_validator/object_validator'
require_relative 'schema_validator/array_validator'
require_relative 'schema_validator/any_of_validator'
require_relative 'schema_validator/all_of_validator'
require_relative 'schema_validator/one_of_validator'
require_relative 'schema_validator/nil_validator'
require_relative 'schema_validator/unspecified_type_validator'

class OpenAPIParser::SchemaValidator
  # validate value by schema
  # this module for SchemaValidators::Base
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  module Validatable
    def validate_schema(value, schema, **keyword_args)
      raise 'implement'
    end

    # validate integer value by schema
    # this method use from float_validator because number allow float and integer
    # @param [Object] _value
    # @param [OpenAPIParser::Schemas::Schema] _schema
    def validate_integer(_value, _schema)
      raise 'implement'
    end
  end

  include Validatable

  class << self
    # validate schema data
    # @param [Hash] value
    # @param [OpenAPIParser::Schemas:v:Schema]
    # @param [OpenAPIParser::SchemaValidator::Options] options
    # @return [Object] coerced or original params
    def validate(value, schema, options, validation_scope = 'SchemaValidator')
      new(value, schema, options, validation_scope).validate_data
    end
  end

  # @param [Hash] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  # @param [OpenAPIParser::SchemaValidator::Options] options
  def initialize(value, schema, options, validation_scope)
    @value = value
    @schema = schema
    @coerce_value = options.coerce_value
    @datetime_coerce_class = options.datetime_coerce_class

    @validation_scope = validation_scope
  end

  # execute validate data
  # @return [Object] coerced or original params
  def validate_data
    coerced, err = validate_schema(@value, @schema)
    raise err if err

    coerced
  end

  # validate value eby schema
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_schema(value, schema, **keyword_args)
    return [value, nil] unless schema

    if (v = validator(value, schema))
      if keyword_args.empty?
        return v.coerce_and_validate(value, schema)
      else
        return v.coerce_and_validate(value, schema, **keyword_args)
      end
    end

    # unknown return error
    OpenAPIParser::ValidateError.build_error_result(value, schema)
  end

  # validate integer value by schema
  # this method use from float_validator because number allow float and integer
  # @param [Object] value
  # @param [OpenAPIParser::Schemas::Schema] schema
  def validate_integer(value, schema)
    integer_validator.coerce_and_validate(value, schema)
  end

  private

    # @return [OpenAPIParser::SchemaValidator::Base, nil]
    def validator(value, schema)
      return any_of_validator if schema.any_of
      return all_of_validator if schema.all_of
      return one_of_validator if schema.one_of
      return nil_validator if value.nil?

      case schema.type
      when 'string'
        string_validator
      when 'integer'
        integer_validator
      when 'boolean'
        boolean_validator
      when 'number'
        float_validator
      when 'object'
        object_validator
      when 'array'
        array_validator
      else
        unspecified_type_validator
      end
    end

    def string_validator
      @string_validator ||= OpenAPIParser.const_get("#{@validation_scope}::StringValidator").new(self, @coerce_value, @datetime_coerce_class)
    end

    def integer_validator
      @integer_validator ||= OpenAPIParser.const_get("#{@validation_scope}::IntegerValidator").new(self, @coerce_value)
    end

    def float_validator
      @float_validator ||= OpenAPIParser.const_get("#{@validation_scope}::FloatValidator").new(self, @coerce_value)
    end

    def boolean_validator
      @boolean_validator ||= OpenAPIParser.const_get("#{@validation_scope}::BooleanValidator").new(self, @coerce_value)
    end

    def object_validator
      @object_validator ||= OpenAPIParser.const_get("#{@validation_scope}::ObjectValidator").new(self, @coerce_value)
    end

    def array_validator
      @array_validator ||= OpenAPIParser.const_get("#{@validation_scope}::ArrayValidator").new(self, @coerce_value)
    end

    def any_of_validator
      @any_of_validator ||= OpenAPIParser.const_get("#{@validation_scope}::AnyOfValidator").new(self, @coerce_value)
    end

    def all_of_validator
      @all_of_validator ||= OpenAPIParser.const_get("#{@validation_scope}::AllOfValidator").new(self, @coerce_value)
    end

    def one_of_validator
      @one_of_validator ||= OpenAPIParser.const_get("#{@validation_scope}::OneOfValidator").new(self, @coerce_value)
    end

    def nil_validator
      @nil_validator ||= OpenAPIParser.const_get("#{@validation_scope}::NilValidator").new(self, @coerce_value)
    end

    def unspecified_type_validator
      @unspecified_type_validator ||= OpenAPIParser.const_get("#{@validation_scope}::UnspecifiedTypeValidator").new(self, @coerce_value)
    end
end
