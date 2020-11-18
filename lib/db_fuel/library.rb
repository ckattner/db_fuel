# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require_relative 'library/dbee/query'
require_relative 'library/dbee/range'

Burner::Jobs.register('db_fuel/dbee/query', DbFuel::Library::Dbee::Query)
Burner::Jobs.register('db_fuel/dbee/range', DbFuel::Library::Dbee::Range)
