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
    module ActiveRecord
      # This job will insert or update records.
      # It will use the unique_keys to first run a query to see if it exists.
      # Each unique_key becomes a WHERE clause. If a record is found it will then
      # update the found record using the primary key specified.
      # If a record is updated or created the record's id will be set to the primary_keyed_column.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class Upsert < Base
        attr_reader :primary_keyed_column, :timestamps, :unique_attribute_renderers

        # Arguments:
        #   name: name of the job within the Burner::Pipeline.
        #
        #   table_name [required]: name of the table to use for the INSERT OR UPDATE statements.
        #
        #   attributes:  Used to specify which object properties to put into the
        #                SQL statement and also allows for one last custom transformation
        #                pipeline, in case the data calls for SQL-specific transformers
        #                before mutation.
        #
        #   debug:       If debug is set to true (defaults to false) then the SQL statements and
        #                returned objects will be printed in the output.  Only use this option while
        #                debugging issues as it will fill
        #                up the output with (potentially too much) data.
        #
        #   primary_keyed_column [required]: Used to set the object's property to the
        #                                returned primary key from the
        #                                INSERT statement or used as the
        #                                WHERE clause for the UPDATE statement.
        #
        #   separator: Just like other jobs with a 'separator' option, if the objects require
        #              key-path notation or nested object support, you can set the separator
        #              to something non-blank (like a period for notation in the
        #              form of: name.first).
        #
        #   timestamps: If timestamps is true (default behavior) then the updated_at column will
        #               automatically have its value set
        #               to the current UTC timestamp if a record was updated.
        #               If a record was created the
        #               created_at and updated_at columns will be set.
        #
        #   unique_attributes: Each key will become a WHERE clause in
        #                      order to check for the existence of a specific record.
        def initialize(
          table_name:,
          primary_keyed_column:,
          name: '',
          attributes: [],
          debug: false,
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
            register: register,
            separator: separator
          )

          @primary_keyed_column = Modeling::KeyedColumn.make(primary_keyed_column, nullable: true)

          @unique_attribute_renderers = attribute_renderers_set
                                        .make_renderers(unique_attributes)

          @timestamps = timestamps

          freeze
        end

        def perform(output, payload)
          raise ArgumentError, 'primary_keyed_column is required' unless primary_keyed_column

          total_inserted = 0
          total_updated  = 0

          payload[register] = array(payload[register])

          payload[register].each do |row|
            record_updated = insert_or_update(output, row, payload.time)

            if record_updated
              total_updated += 1
            else
              total_inserted += 1
            end
          end

          output.detail("Total Updated: #{total_updated}")
          output.detail("Total Inserted: #{total_inserted}")
        end

        protected

        def find_record(output, row, time)
          unique_row = attribute_renderers_set.transform(unique_attribute_renderers, row, time)

          first_sql = db_provider.first_sql(unique_row)

          debug_detail(output, "Find Statement: #{first_sql}")

          first_record = db_provider.first(unique_row)

          id = resolver.get(first_record, primary_keyed_column.column)

          resolver.set(row, primary_keyed_column.key, id)

          debug_detail(output, "Record Exists: #{first_record}") if first_record

          first_record
        end

        def insert_record(output, row, time)
          dynamic_attrs = if timestamps
                            # doing an INSERT and timestamps should be set
                            # set the created_at and updated_at fields
                            attribute_renderers_set.timestamp_created_attribute_renderers
                          else
                            attribute_renderers_set.attribute_renderers
                          end

          set_object = attribute_renderers_set.transform(dynamic_attrs, row, time)

          insert_sql = db_provider.insert_sql(set_object)

          debug_detail(output, "Insert Statement: #{insert_sql}")

          id = db_provider.insert(set_object)

          # add the primary key name and value to row if primary_keyed_column was specified
          resolver.set(row, primary_keyed_column.key, id) if primary_keyed_column

          debug_detail(output, "Insert Return: #{row}")
        end

        # Updates only a single record. Lookups primary key to update the record.
        def update_record(output, row, time)
          raise ArgumentError, 'primary_keyed_column is required' unless primary_keyed_column

          first_record = find_record(output, row, time)

          if first_record
            debug_detail(output, "Record Exists: #{first_record}")

            id = resolver.get(first_record, primary_keyed_column.column)

            where_object = { primary_keyed_column.column => id }

            # update record using the primary key as the WHERE clause
            update(output, row, time, where_object)
          end

          first_record
        end

        # Updates one or many records depending on where_object passed
        def update(output, row, time, where_object)
          dynamic_attrs = if timestamps
                            # doing an UPDATE and timestamps should be set,
                            # modify the updated_at field, don't modify the created_at field
                            attribute_renderers_set.timestamp_updated_attribute_renderers
                          else
                            attribute_renderers_set.attribute_renderers
                          end

          set_object = attribute_renderers_set.transform(dynamic_attrs, row, time)

          update_sql = db_provider.update_sql(set_object, where_object)

          debug_detail(output, "Update Statement: #{update_sql}")

          debug_detail(output, "Update Return: #{row}")

          db_provider.update(set_object, where_object)
        end

        private

        def insert_or_update(output, row, time)
          first_record = update_record(output, row, time)

          if first_record
            first_record
          else
            # create the record
            insert_record(output, row, time)
            nil
          end
        end
      end
    end
  end
end
