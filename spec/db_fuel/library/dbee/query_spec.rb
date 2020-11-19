# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Library::Dbee::Query do
  before(:each) do
    load_data
  end

  let(:output)   { make_burner_output }
  let(:register) { 'register_a' }

  let(:config) do
    {
      name: 'test_job',
      model: {
        name: :patients
      },
      query: {
        fields: [
          { key_path: :id },
          { key_path: :first_name }
        ],
        sorters: [
          { key_path: :first_name }
        ]
      },
      register: register
    }
  end

  let(:payload) { Burner::Payload.new }

  subject { described_class.make(config) }

  describe '#perform' do
    before(:each) do
      subject.perform(output, payload)
    end

    specify 'output contains number of records' do
      string_summary = output.outs.first

      expect(string_summary.string).to include("Loading 3 record(s) into #{register}")
    end

    specify 'payload register has data' do
      records = payload[register]

      expect(records.length).to eq(3)

      expect(records[0]).to include('first_name' => 'Bozo')
      expect(records[1]).to include('first_name' => 'Bugs')
      expect(records[2]).to include('first_name' => 'Frank')
    end
  end

  describe 'README examples' do
    specify 'basic patient query' do
      pipeline = {
        jobs: [
          {
            name: 'retrieve_patients',
            type: 'db_fuel/dbee/query',
            model: {
              name: :patients
            },
            query: {
              fields: [
                { key_path: :id },
                { key_path: :first_name }
              ],
              sorters: [
                { key_path: :first_name }
              ]
            },
            register: :patients
          }
        ],
        steps: %w[retrieve_patients]
      }

      payload = Burner::Payload.new

      Burner::Pipeline.make(pipeline).execute(output: make_burner_output, payload: payload)

      actual = payload['patients']

      expected = [
        {
          'id' => 7,
          'first_name' => 'Bozo'
        },
        {
          'id' => 9,
          'first_name' => 'Bugs'
        },
        {
          'id' => 8,
          'first_name' => 'Frank'
        }
      ]

      expect(actual).to eq(expected)
    end
  end
end
