# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Library::ActiveRecord::Update do
  before(:each) do
    load_data
  end

  let(:output)        { make_burner_output }
  let(:register)      { 'register_a' }
  let(:debug)         { false }
  let(:keys_register) { 'register_for_keys' }
  let(:keys)          { [] }

  let(:config) do
    {
      name: 'test_job',
      register: register,
      keys_register: keys_register,
      debug: debug,
      attributes: [
        { key: :first_name },
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: { key: :id },
      unique_attributes: [
        { key: :chart_number }
      ]
    }
  end

  let(:patients) do
    [
      { 'chart_number' => 'C0001', 'first_name' => 'BOZZY', 'last_name' => 'CLOWNZY' },
      { 'chart_number' => 'R0001', 'first_name' => 'FRANKY', 'last_name' => 'RIZZY' }
    ]
  end

  let(:chart_numbers) { patients.map { |p| p['chart_number'] } }

  let(:payload) do
    Burner::Payload.new(
      registers: {
        keys_register => keys,
        register => patients.map { |p| {}.merge(p) } # shallow copy to preserve original
      }
    )
  end

  let(:written) { output.outs.first.string }

  subject { described_class.make(config) }

  describe '#perform' do
    before(:each) do
      subject.perform(output, payload)
    end

    it 'updates scoped records with specified attributes' do
      db_patients = Patient
                    .order(:chart_number)
                    .where(chart_number: chart_numbers)
                    .select(:chart_number, :first_name, :last_name)
                    .as_json(except: :id)

      expect(db_patients.count).to eq(2)
      expect(db_patients).to       eq(patients)
    end

    it 'does not update outside scoped records' do
      db_patients = Patient
                    .order(:chart_number)
                    .where.not(chart_number: chart_numbers)
                    .select(:chart_number, :first_name, :last_name)
                    .as_json(except: :id)

      expected = [
        {
          'chart_number' => 'B0001',
          'first_name' => 'Bugs',
          'last_name' => 'Bunny'
        }
      ]

      expect(db_patients.count).to eq(1)
      expect(db_patients).to       eq(expected)
    end

    it 'outputs total affect row count' do
      expect(written).to include('Total Rows Affected: 2')
    end

    context 'when debug is true' do
      let(:debug) { true }

      it 'outputs SQL statements' do
        expect(written).to include('Update Statement: UPDATE "patients"')
      end

      it 'outputs return objects' do
        expect(written).to include('Individual Rows Affected:')
      end
    end

    context 'when debug is false' do
      it 'does not output does SQL statements' do
        expect(written).not_to include('Update Statement: UPDATE "patients"')
      end

      it 'does not output return objects' do
        expect(written).not_to include('Individual Rows Affected:')
      end
    end

    context 'when keys_register has at least one key' do
      let(:keys) { %w[chart_number first_name] }

      it 'outputs list of keys' do
        expect(written).to include("keys: #{keys.join(', ')}")
      end

      it 'only updates keys in keys_register' do
        actual = Patient
                 .order(:chart_number)
                 .select(:chart_number, :first_name, :last_name)
                 .as_json(except: :id)

        expected = [
          { 'chart_number' => 'B0001', 'first_name' => 'Bugs', 'last_name' => 'Bunny' },
          { 'chart_number' => 'C0001', 'first_name' => 'BOZZY', 'last_name' => 'Clown' },
          { 'chart_number' => 'R0001', 'first_name' => 'FRANKY', 'last_name' => 'Rizzo' }
        ]

        expect(actual).to match(expected)
      end
    end
  end

  describe 'README examples' do
    specify 'patient update' do
      pipeline = {
        jobs: [
          {
            name: :load_patients,
            type: 'b/value/static',
            register: :patients,
            value: [
              { chart_number: 'B0001', last_name: 'Fox' },
              { chart_number: 'C0001', last_name: 'Smurf' }
            ]
          },
          {
            name: 'update_patients',
            type: 'db_fuel/active_record/update',
            register: :patients,
            attributes: [
              { key: :last_name }
            ],
            table_name: 'patients',
            primary_keyed_column: { key: :id },
            unique_attributes: [
              { key: :chart_number }
            ]
          }
        ]
      }

      payload = Burner::Payload.new

      Burner::Pipeline.make(pipeline).execute(output: output, payload: payload)

      actual = Patient
               .order(:chart_number)
               .select(:chart_number, :first_name, :last_name)
               .as_json(except: :id)

      expected = [
        { 'chart_number' => 'B0001', 'first_name' => 'Bugs', 'last_name' => 'Fox' },
        { 'chart_number' => 'C0001', 'first_name' => 'Bozo', 'last_name' => 'Smurf' },
        { 'chart_number' => 'R0001', 'first_name' => 'Frank', 'last_name' => 'Rizzo' }
      ]

      expect(actual).to eq(expected)
    end
  end
end
