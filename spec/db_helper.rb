# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

# Enable logging using something like:
# ActiveRecord::Base.logger = Logger.new(STDERR)

require 'file_helper'

class Status < ActiveRecord::Base
  has_many :patients
end

class Patient < ActiveRecord::Base
  belongs_to :status
end

def connect_to_db(name)
  config = read_yaml_file('spec', 'config', 'database.yaml')[name.to_s]
  ActiveRecord::Base.establish_connection(config)
end

def load_schema
  ActiveRecord::Schema.define do
    create_table :statuses do |t|
      t.string  :code,     null: false, limit: 25
      t.integer :priority, null: false, default: 0
      t.timestamps
    end

    create_table :patients do |t|
      t.string     :chart_number
      t.string     :first_name
      t.string     :middle_name
      t.string     :last_name
      t.references :status
      t.timestamps
    end
  end
end

def clear_data
  Patient.delete_all
  Status.delete_all
end

def load_data
  active_status   = Status.create!(code: 'Active', priority: 1)
  inactive_status = Status.create!(code: 'Inactive', priority: 2)

  Patient.create!(
    first_name: 'Bozo',
    middle_name: 'The',
    last_name: 'Clown',
    status: active_status
  )

  Patient.create!(
    first_name: 'Frank',
    last_name: 'Rizzo',
    status: active_status
  )

  Patient.create!(
    first_name: 'Bugs',
    middle_name: 'The',
    last_name: 'Bunny',
    status: inactive_status
  )
end
