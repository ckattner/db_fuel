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
        def perform(output, payload)
          records = execute(sql)

          load_register(records, output, payload)
        end

        private

        def sql
          ::Dbee.sql(model, query, provider)
        end
      end
    end
  end
end
