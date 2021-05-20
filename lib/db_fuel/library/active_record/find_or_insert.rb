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
      # This job is a slight enhancement to the insert job, in that it will only insert new
      # records.  It will use the unique_keys to first run a query to see if it exists.
      # Each unique_key becomes a WHERE clause.  If primary_keyed_column is specified
      # and a record is found then the first record's id will be set to
      # the primary_keyed_column.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class FindOrInsert < Upsert
        # attr_reader :unique_attribute_renderers

        # Arguments:
        #   name: name of the job within the Burner::Pipeline.
        #
        #   table_name [required]: name of the table to use for the INSERT statements.
        #
        #   attributes:  Used to specify which object properties to put into the
        #                SQL statement and also allows for one last custom transformation
        #                pipeline, in case the data calls for SQL-specific transformers
        #                before insertion.
        #
        #   debug: If debug is set to true (defaults to false) then the SQL statements and
        #          returned objects will be printed in the output.  Only use this option while
        #          debugging issues as it will fill up the output with (potentially too much) data.
        #
        #   primary_keyed_column: If primary_keyed_column is present then it will be used to set
        #                     the object's property to the returned primary key
        #                       from the INSERT statement.
        #
        #   separator: Just like other jobs with a 'separator' option, if the objects require
        #              key-path notation or nested object support, you can set the separator
        #              to something non-blank (like a period for notation in the
        #              form of: name.first).
        #
        #   timestamps: If timestamps is true (default behavior) then both created_at
        #               and updated_at columns will automatically have their values set
        #               to the current UTC timestamp.
        #
        #   unique_attributes: Each key will become a WHERE clause in order check for record
        #                      existence before insertion attempt.
        def initialize(
          table_name:,
          name: '',
          attributes: [],
          debug: false,
          keys_register: nil,
          primary_keyed_column: nil,
          register: Burner::DEFAULT_REGISTER,
          separator: '',
          timestamps: true,
          unique_attributes: []
        )

          super(
            name: name,
            keys_register: keys_register,
            table_name: table_name,
            attributes: attributes,
            debug: debug,
            primary_keyed_column: primary_keyed_column,
            register: register,
            separator: separator,
            timestamps: timestamps,
            unique_attributes: unique_attributes
          )
        end

        def perform(output, payload)
          total_inserted = 0
          total_existed  = 0

          payload[register] = array(payload[register])
          keys              = resolve_key_set(output, payload)

          payload[register].each do |row|
            exists = find_record(output, row, payload.time)

            if exists
              total_existed += 1
              next
            end

            insert_record(output, row, payload.time, keys)

            total_inserted += 1
          end

          output.detail("Total Existed: #{total_existed}")
          output.detail("Total Inserted: #{total_inserted}")
        end
      end
    end
  end
end
