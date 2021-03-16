# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'upsert'

module DbFuel
  module Library
    module ActiveRecord
      # This job can take the unique objects in a register and updates them within database table.
      # The attributes translate to SQL SET clauses and the unique_keys translate to
      # WHERE clauses to find the records to update.
      # The primary_keyed_column is used to update the unique record.
      # Only one record will be updated per statement.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class Update < Upsert
        # Arguments:
        #   name: name of the job within the Burner::Pipeline.
        #
        #   table_name [required]: name of the table to use for the INSERT statements.
        #
        #   attributes:  Used to specify which object properties to put into the
        #                SQL statement and also allows for one last custom transformation
        #                pipeline, in case the data calls for SQL-specific transformers
        #                before mutation.
        #
        #   debug: If debug is set to true (defaults to false) then the SQL statements and
        #          returned objects will be printed in the output.  Only use this option while
        #          debugging issues as it will fill up the output with (potentially too much) data.
        #
        #   primary_keyed_column [required]: Primary key column for the corresponding table.
        #                           Used as the WHERE clause for the UPDATE statement.
        #                           Only one record will be updated at a time
        #                           using the primary key specified.
        #
        #   separator: Just like other jobs with a 'separator' option, if the objects require
        #              key-path notation or nested object support, you can set the separator
        #              to something non-blank (like a period for notation in the
        #              form of: name.first).
        #
        #   timestamps: If timestamps is true (default behavior) then the updated_at column will
        #               automatically have its value set to the current UTC timestamp.
        #
        #   unique_attributes: Each key will become a WHERE clause in order to only find specific
        #                      records. The UPDATE statement's WHERE
        #                      clause will use the primary key specified.
        def initialize(
          table_name:,
          name: '',
          attributes: [],
          debug: false,
          primary_keyed_column: nil,
          register: Burner::DEFAULT_REGISTER,
          separator: '',
          timestamps: true,
          unique_attributes: []
        )

          attributes = Burner::Modeling::Attribute.array(attributes)

          super(
            name: name,
            table_name: table_name,
            attributes: attributes,
            debug: debug,
            primary_keyed_column: primary_keyed_column,
            register: register,
            separator: separator,
            timestamps: timestamps,
            unique_attributes: unique_attributes
          )

          freeze
        end

        def perform(output, payload)
          total_rows_affected = 0

          payload[register] = array(payload[register])

          payload[register].each do |row|
            rows_affected = 0

            first_record = update_record(output, row, payload.time)

            rows_affected = 1 if first_record

            debug_detail(output, "Individual Rows Affected: #{rows_affected}")

            total_rows_affected += rows_affected
          end

          output.detail("Total Rows Affected: #{total_rows_affected}")
        end
      end
    end
  end
end
