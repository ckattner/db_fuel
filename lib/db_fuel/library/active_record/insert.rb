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
      # This job can take the objects in a register and insert them into a database table.
      #
      # Expected Payload[register] input: array of objects
      # Payload[register] output: array of objects.
      class Insert < Base
        attr_reader :primary_key

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
        def initialize(
          name:,
          table_name:,
          attributes: [],
          debug: false,
          primary_key: nil,
          register: Burner::DEFAULT_REGISTER,
          separator: '',
          timestamps: true
        )
          explicit_attributes = Burner::Modeling::Attribute.array(attributes)

          attributes = timestamps ? timestamp_attributes + explicit_attributes : explicit_attributes

          super(
            name: name,
            table_name: table_name,
            attributes: attributes,
            debug: debug,
            register: register,
            separator: separator
          )

          @primary_key = Modeling::KeyedColumn.make(primary_key, nullable: true)
        end

        def perform(output, payload)
          payload[register] = array(payload[register])

          payload[register].each { |row| insert(output, row, payload.time) }
        end

        private

        def insert(output, row, time)
          transformed_row = transform(attribute_renderers, row, time)

          output_sql(output, transformed_row)
          insert_and_mutate(output, transformed_row, row)
        end

        def output_sql(output, row)
          sql = db_provider.insert_sql(row)

          debug_detail(output, "Insert Statement: #{sql}")
        end

        def insert_and_mutate(output, row_to_insert, row_to_return)
          id = db_provider.insert(row_to_insert)

          resolver.set(row_to_return, primary_key.key, id) if primary_key

          debug_detail(output, "Insert Return: #{row_to_return}")
        end

        def timestamp_attributes
          [
            created_at_timestamp_attribute,
            updated_at_timestamp_attribute
          ]
        end
      end
    end
  end
end
