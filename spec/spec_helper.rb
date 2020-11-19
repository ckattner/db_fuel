# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'active_record'
require 'pry'
require 'securerandom'
require 'yaml'

require 'db_helper'

unless ENV['DISABLE_SIMPLECOV'] == 'true'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    add_filter %r{\A/spec/}
  end
end

RSpec.configure do |config|
  config.before(:suite) do
    connect_to_db(:sqlite)
    load_schema
  end

  config.before(:each) do
    clear_data
  end
end

require 'rspec/expectations'

require './lib/db_fuel'

def make_burner_output
  Burner::Output.new(outs: [StringIO.new])
end
