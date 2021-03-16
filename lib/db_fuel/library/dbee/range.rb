# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'base'

module DbFuel
  module Library
    module Dbee
      # This Burner Job does the same data query and loading as the Query Job with the addition
      # of the ability to dynamically add an IN filter for a range of values.  The values are
      # retrieved from the register's array of records using the defined key.
      #
      # Expected Payload[register] input: array of objects.
      # Payload[register] output: array of objects.
      class Range < Base
        attr_reader :key,
                    :key_path,
                    :resolver

        # Arguments:
        # - key:       Specifies which key to use to aggregate a list of values for within
        #              the specified register's dataset.
        # - key_path:  Specifies the Dbee identifier (column) to use for the IN filter.
        # - model:     Dbee Model configuration
        # - query:     Dbee Query configuration
        # - register:  Name of the register to use for gathering the IN clause values and where
        #              to store the resulting recordset.
        # - separator: Character to use to split the key-path for nested object support.
        #
        # - debug:     If debug is set to true (defaults to false) then the SQL statements
        #              will be printed in the output.  Only use this option while
        #              debugging issues as it will fill
        #              up the output with (potentially too much) data.
        def initialize(
          key:,
          name: '',
          key_path: '',
          model: {},
          query: {},
          register: Burner::DEFAULT_REGISTER,
          separator: '',
          debug: false
        )
          raise ArgumentError, 'key is required' if key.to_s.empty?

          @key      = key.to_s
          @key_path = key_path.to_s.empty? ? @key : key_path.to_s
          @resolver = Objectable.resolver(separator: separator)

          super(
            model: model,
            name: name,
            query: query,
            register: register,
            debug: debug
          )
        end

        def perform(output, payload)
          records = execute(sql(output, payload))

          load_register(records, output, payload)
        end

        private

        def map_values(payload)
          array(payload[register]).map { |o| resolver.get(o, key) }.compact
        end

        def dynamic_filters(payload)
          values = map_values(payload)

          return [] if values.empty?

          [
            {
              type: :equals,
              key_path: key_path,
              value: values,
            }
          ]
        end

        def compile_dbee_query(payload)
          ::Dbee::Query.make(
            fields: query.fields,
            filters: query.filters + dynamic_filters(payload),
            limit: query.limit,
            sorters: query.sorters
          )
        end

        def sql(output, payload)
          dbee_query = compile_dbee_query(payload)
          sql_statement = ::Dbee.sql(model, dbee_query, provider)

          debug_detail(output, "Range SQL: #{sql_statement}")

          sql_statement
        end
      end
    end
  end
end
