# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module DbFuel
  module Modeling
    # Connects a hash key to a SQL column.  By default if a column is not given then its
    # key will be used for both.  The general use case for this is for mapping objects
    # to SQL and SQL to objects.
    class KeyedColumn
      acts_as_hashable

      attr_reader :column, :key

      def initialize(key:, column: '')
        raise ArgumentError, 'key is required' if key.blank?

        @column = column.present? ? column.to_s : key.to_s
        @key    = key.to_s

        freeze
      end
    end
  end
end
