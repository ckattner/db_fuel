# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'insert'

module DbFuel
  module Library
    module ActiveRecord
      # This job is a slight enhancement to the insert job, in that it will only insert new
      # records.  It will use the unique_keys to first run a query to see if it exists.
      # Each unique_key becomes a WHERE clause.  If primary_key is specified and a record is
      # found then the first record's id will be set to the primary_key.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class FindOrInsert < Insert
        attr_reader :unique_attribute_renderers

        # Arguments:
        #   name [required]: name of the job within the Burner::Pipeline.
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
        #   primary_key: If primary_key is present then it will be used to set the object's
        #                property to the returned primary key from the INSERT statement.
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
          name:,
          table_name:,
          attributes: [],
          debug: false,
          primary_key: nil,
          register: Burner::DEFAULT_REGISTER,
          separator: '',
          timestamps: true,
          unique_attributes: []
        )
          super(
            name: name,
            table_name: table_name,
            attributes: attributes,
            debug: debug,
            primary_key: primary_key,
            register: register,
            separator: separator,
            timestamps: timestamps
          )

          @unique_attribute_renderers = make_attribute_renderers(unique_attributes)
        end

        def perform(output, payload)
          total_inserted = 0
          total_existed  = 0

          payload[register] = array(payload[register])

          payload[register].each do |row|
            exists = existence_check_and_mutate(output, row, payload.time)

            if exists
              total_existed += 1
              next
            end

            insert(output, row, payload.time)

            total_inserted += 1
          end

          output.detail("Total Existed: #{total_existed}")
          output.detail("Total Inserted: #{total_inserted}")
        end

        private

        def existence_check_and_mutate(output, row, time)
          unique_row = transform(unique_attribute_renderers, row, time)

          first_sql = db_provider.first_sql(unique_row)
          debug_detail(output, "Find Statement: #{first_sql}")

          first_record = db_provider.first(unique_row)

          return false unless first_record

          if primary_key
            id = resolver.get(first_record, primary_key.column)

            resolver.set(row, primary_key.key, id)
          end

          debug_detail(output, "Record Exists: #{first_record}")

          true
        end
      end
    end
  end
end
