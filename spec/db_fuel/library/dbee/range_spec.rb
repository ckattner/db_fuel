# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Library::Dbee::Range do
  before(:each) do
    load_data
  end

  let(:output)   { make_burner_output }
  let(:register) { 'register_a' }
  let(:debug)    { false }

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
      register: register,
      key: :fname,
      key_path: :first_name,
      debug: debug,
    }
  end

  let(:patients) do
    [
      # This entry has string key(s) to illustrate how keys are treated indifferently.
      # The library Objectable is used under-the-hood, which provides a more resilient
      # object attribute/method interface.  See the Objectable library for more info:
      # https://github.com/bluemarblepayroll/objectable
      { 'fname' => 'Bozo' },
      { fname: 'Bugs' },
      { fname: 'DoesntExist' }
    ]
  end

  let(:payload) do
    Burner::Payload.new(
      registers: {
        register => patients
      }
    )
  end

  let(:written) { output.outs.first.string }

  subject { described_class.make(config) }

  describe '#perform' do
    before(:each) do
      subject.perform(output, payload)
    end

    specify 'output contains number of records' do
      expect(written).to include("Loading 2 record(s) into #{register}")
    end

    specify 'payload register has data' do
      records = payload[register]

      expect(records.length).to eq(2)

      expect(records[0]).to include('first_name' => 'Bozo')
      expect(records[1]).to include('first_name' => 'Bugs')
    end

    context 'when debug is true' do
      let(:debug) { true }

      it 'outputs SQL statements' do
        expect(written).to include('Range SQL:')
      end
    end

    context 'when debug is false' do
      it 'does not output does SQL statements' do
        expect(written).not_to include('Range SQL:')
      end
    end
  end

  describe 'README examples' do
    specify 'basic patient query' do
      pipeline = {
        jobs: [
          {
            name: :load_first_names,
            type: 'b/value/static',
            register: :patients,
            value: [
              { fname: 'Bozo' },
              { fname: 'Bugs' },
            ]
          },
          {
            name: 'retrieve_patients',
            type: 'db_fuel/dbee/range',
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
            register: :patients,
            key: :fname,
            key_path: :first_name
          }
        ]
      }

      payload = Burner::Payload.new

      Burner::Pipeline.make(pipeline).execute(output: make_burner_output, payload: payload)

      actual = payload['patients']

      expect(actual.length).to eq(2)
      expect(actual[0]).to     include('first_name' => 'Bozo')
      expect(actual[1]).to     include('first_name' => 'Bugs')
    end
  end
end
