# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'pry'
require 'securerandom'
require 'yaml'

unless ENV['DISABLE_SIMPLECOV'] == 'true'
  require 'simplecov'
  require 'simplecov-console'

  SimpleCov.formatter = SimpleCov::Formatter::Console
  SimpleCov.start do
    add_filter %r{\A/spec/}
  end
end

TEMP_DIR = File.join('tmp', 'spec')

RSpec.configure do |config|
  config.before(:suite) do
    FileUtils.rm_rf(TEMP_DIR)
  end
end

require 'rspec/expectations'

require './lib/db_fuel'
