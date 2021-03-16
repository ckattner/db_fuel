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
      # Executes a Dbee Query against a Dbee Model and stores the resulting records
      # in the designated payload register.
      #
      # Expected Payload[register] input: nothing
      # Payload[register] output: array of objects.
      class Query < Base
        # Arguments:
        # - name:      Name of job.
        # - model:     Dbee Model configuration
        # - query:     Dbee Query configuration
        #
        # - register:  Name of the register to use for gathering the IN clause values and where
        #              to store the resulting recordset.
        #
        # - debug:     If debug is set to true (defaults to false) then the SQL statements
        #              will be printed in the output.  Only use this option while
        #              debugging issues as it will fill
        #              up the output with (potentially too much) data.
        def initialize(
          name: '',
          model: {},
          query: {},
          register: Burner::DEFAULT_REGISTER,
          debug: false
        )
          super(
            model: model,
            name: name,
            query: query,
            register: register,
            debug: debug
          )
        end

        def perform(output, payload)
          records = execute(sql(output))

          load_register(records, output, payload)
        end

        private

        def sql(output)
          sql_statement = ::Dbee.sql(model, query, provider)

          debug_detail(output, "Query SQL: #{sql_statement}")

          sql_statement
        end
      end
    end
  end
end
