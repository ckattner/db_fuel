# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module DbFuel
  module Library
    module Dbee
      # Common code shared between all Dbee subclasses.
      class Base < Burner::JobWithRegister
        attr_reader :model,
                    :provider,
                    :query,
                    :debug

        # Arguments:
        # - model:    Dbee Model configuration
        # - query:    Dbee Query configuration
        # - register: Name of the register to use for gathering the IN clause values and where
        #             to store the resulting recordset.
        def initialize(
          name: '',
          model: {},
          query: {},
          register: Burner::DEFAULT_REGISTER,
          debug: false
        )
          super(name: name, register: register)

          @model    = ::Dbee::Model.make(model)
          @provider = ::Dbee::Providers::ActiveRecordProvider.new
          @query    = ::Dbee::Query.make(query)
          @debug    = debug || false

          freeze
        end

        protected

        def execute(sql)
          ::ActiveRecord::Base.connection.exec_query(sql).to_a
        end

        def load_register(records, output, payload)
          output.detail("Loading #{records.length} record(s) into #{register}")

          payload[register] = records
        end

        def debug_detail(output, message)
          return unless debug

          output.detail(message)
        end
      end
    end
  end
end
