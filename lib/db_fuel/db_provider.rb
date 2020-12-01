# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module DbFuel
  # Intermediate internal API for Arel/ActiveRecord.  There is some overlap in job needs when
  # it comes to the Arel interface so this class condenses down those needs into this class.
  class DbProvider # :nodoc: all
    attr_reader :arel_table

    def initialize(table_name)
      raise ArgumentError, 'table_name is required' if table_name.to_s.empty?

      @arel_table = ::Arel::Table.new(table_name.to_s)

      freeze
    end

    def first(object)
      sql = first_sql(object)

      ::ActiveRecord::Base.connection.exec_query(sql).first
    end

    def first_sql(object)
      relation = arel_table.project(Arel.star).take(1)
      manager  = apply_where(object, relation)

      manager.to_sql
    end

    def insert_sql(object)
      insert_manager(object).to_sql
    end

    def insert(object)
      manager = insert_manager(object)

      ::ActiveRecord::Base.connection.insert(manager)
    end

    def update(set_object, where_object)
      manager = update_manager(set_object, where_object)

      ::ActiveRecord::Base.connection.update(manager)
    end

    def update_sql(set_object, where_object)
      update_manager(set_object, where_object).to_sql
    end

    private

    def update_manager(set_object, where_object)
      arel_row       = make_arel_row(set_object)
      update_manager = ::Arel::UpdateManager.new.set(arel_row).table(arel_table)

      apply_where(where_object, update_manager)
    end

    def apply_where(hash, manager)
      (hash || {}).inject(manager) do |memo, (key, value)|
        memo.where(arel_table[key].eq(value))
      end
    end

    def insert_manager(object)
      arel_row = make_arel_row(object)

      ::Arel::InsertManager.new.insert(arel_row)
    end

    def make_arel_row(row)
      row.map { |key, value| [arel_table[key], value] }
    end
  end
end
