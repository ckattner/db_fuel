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
                    :keys_register,
                    :resolver,
                    :attribute_renderers_set

        def initialize(
          table_name:,
          name: '',
          attributes: [],
          debug: false,
          keys_register: nil,
          register: Burner::DEFAULT_REGISTER,
          separator: ''
        )
          super(name: name, register: register)

          @keys_register           = keys_register.to_s
          @resolver                = Objectable.resolver(separator: separator)
          @attribute_renderers_set = Modeling::AttributeRendererSet.new(resolver: resolver,
                                                                        attributes: attributes)
          @db_provider = DbProvider.new(table_name)
          @debug = debug || false
        end

        protected

        def debug_detail(output, message)
          return unless debug

          output.detail(message)
        end

        def resolve_key_set(output, payload)
          return Set.new if keys_register.empty?

          keys = array(payload[keys_register]).map(&:to_s).to_set

          output.detail("Limiting to only keys: #{keys.to_a.join(', ')}") if keys.any?

          keys
        end
      end
    end
  end
end
