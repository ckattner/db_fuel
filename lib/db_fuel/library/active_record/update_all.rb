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
      # This job can take the objects in a register and updates them within database table.
      # The attributes translate to SQL SET clauses
      # and the unique_keys translate to WHERE clauses.
      # One or more records may be updated at a time.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class UpdateAll < Upsert
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
        #   separator: Just like other jobs with a 'separator' option, if the objects require
        #              key-path notation or nested object support, you can set the separator
        #              to something non-blank (like a period for notation in the
        #              form of: name.first).
        #
        #   timestamps: If timestamps is true (default behavior) then the updated_at column will
        #               automatically have its value set to the current UTC timestamp.
        #
        #   unique_attributes: Each key will become a WHERE clause in order to only update specific
        #                      records.
        def initialize(
          table_name:,
          name: '',
          attributes: [],
          debug: false,
          register: Burner::DEFAULT_REGISTER,
          keys_register: nil,
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
            primary_keyed_column: nil,
            keys_register: keys_register,
            register: register,
            separator: separator,
            timestamps: timestamps,
            unique_attributes: unique_attributes
          )

          freeze
        end

        def perform(output, payload)
          payload[register] = array(payload[register])
          keys              = resolve_key_set(output, payload)

          total_rows_affected = payload[register].inject(0) do |memo, row|
            where_object = attribute_renderers_set.transform(
              unique_attribute_renderers,
              row,
              payload.time
            )

            rows_affected = update(output, row, payload.time, where_object, keys)

            debug_detail(output, "Individual Rows Affected: #{rows_affected}")

            memo + rows_affected
          end

          output.detail("Total Rows Affected: #{total_rows_affected}")
        end
      end
    end
  end
end
