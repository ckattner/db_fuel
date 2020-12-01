# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module DbFuel
  module Library
    module ActiveRecord
      # This job can take the objects in a register and insert them into a database table.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class Base < Burner::JobWithRegister
        CREATED_AT = :created_at
        NOW_TYPE   = 'r/value/now'
        UPDATED_AT = :updated_at

        attr_reader :attribute_renderers,
                    :db_provider,
                    :debug,
                    :resolver

        def initialize(
          name:,
          table_name:,
          attributes: [],
          debug: false,
          register: Burner::DEFAULT_REGISTER,
          separator: ''
        )
          super(name: name, register: register)

          # set resolver first since make_attribute_renderers needs it.
          @resolver            = Objectable.resolver(separator: separator)
          @attribute_renderers = make_attribute_renderers(attributes)
          @db_provider         = DbProvider.new(table_name)
          @debug = debug || false
        end

        private

        def make_attribute_renderers(attributes)
          Burner::Modeling::Attribute
            .array(attributes)
            .map { |a| Burner::Modeling::AttributeRenderer.new(a, resolver) }
        end

        def transform(attribute_renderers, row, time)
          attribute_renderers.each_with_object({}) do |attribute_renderer, memo|
            value = attribute_renderer.transform(row, time)

            resolver.set(memo, attribute_renderer.key, value)
          end
        end

        def created_at_timestamp_attribute
          timestamp_attribute(CREATED_AT)
        end

        def updated_at_timestamp_attribute
          timestamp_attribute(UPDATED_AT)
        end

        def timestamp_attribute(key)
          Burner::Modeling::Attribute.make(
            key: key,
            transformers: [
              { type: NOW_TYPE }
            ]
          )
        end

        def debug_detail(output, message)
          return unless debug

          output.detail(message)
        end
      end
    end
  end
end
