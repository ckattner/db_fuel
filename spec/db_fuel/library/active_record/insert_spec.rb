# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Library::ActiveRecord::Insert do
  let(:output)        { make_burner_output }
  let(:register)      { 'register_a' }
  let(:debug)         { false }
  let(:keys_register) { 'register_for_keys' }
  let(:keys)          { [] }

  let(:config) do
    {
      name: 'test_job',
      keys_register: keys_register,
      register: register,
      debug: debug,
      attributes: [
        { key: :chart_number },
        { key: :first_name },
        { key: :last_name }
      ],
      table_name: 'patients',
      primary_keyed_column: {
        key: :id
      }
    }
  end

  let(:patients) do
    [
      { 'chart_number' => 'AB0', 'first_name' => 'a0', 'last_name' => 'b0' },
      { 'chart_number' => 'AB1', 'first_name' => 'a1', 'last_name' => 'b1' }
    ]
  end

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

    context 'when debug is true' do
      let(:debug) { true }

      it 'outputs SQL statements' do
        expect(written).to include('Insert Statement: INSERT INTO "patients"')
      end

      it 'outputs return objects' do
        expect(written).to include('Insert Return: {')
      end
    end

    context 'when debug is false' do
      it 'does not output does SQL statements' do
        expect(written).not_to include('Insert Statement: INSERT INTO "patients"')
      end

      it 'does not output return objects' do
        expect(written).not_to include('Insert Return: {')
      end
    end

    it 'inserts records with specified attributes' do
      db_patients = Patient
                    .order(:chart_number)
                    .select(:chart_number, :first_name, :last_name)
                    .as_json(except: :id)

      expect(db_patients.count).to eq(2)
      expect(db_patients).to       eq(patients)
    end

    it 'sets timestamp columns' do
      db_patients = Patient.order(:chart_number)

      expect(db_patients.count).to eq(2)

      db_patients.each_with_index do |db_patient, _index|
        expect(db_patient.created_at).not_to be nil
        expect(db_patient.updated_at).not_to be nil
      end
    end

    context 'when keys_register has at least one key' do
      let(:keys) { %w[chart_number] }

      it 'outputs list of keys' do
        expect(written).to include("keys: #{keys.join(', ')}")
      end

      it 'only inserts values for keys in keys_register' do
        db_patients = Patient
                      .order(:chart_number)
                      .select(:chart_number, :first_name, :last_name)
                      .as_json(except: :id)

        expected = [
          { 'chart_number' => 'AB0', 'first_name' => nil, 'last_name' => nil },
          { 'chart_number' => 'AB1', 'first_name' => nil, 'last_name' => nil }
        ]

        expect(db_patients).to match(expected)
      end
    end
  end

  describe 'README examples' do
    specify 'patient insert' do
      pipeline = {
        jobs: [
          {
            name: :load_patients,
            type: 'b/value/static',
            register: :patients,
            value: [
              { chart_number: 'B0001', first_name: 'Bugs', last_name: 'Bunny' },
              { chart_number: 'B0002', first_name: 'Babs', last_name: 'Bunny' }
            ]
          },
          {
            name: 'insert_patients',
            type: 'db_fuel/active_record/insert',
            register: :patients,
            attributes: [
              { key: :chart_number },
              { key: :first_name },
              { key: :last_name }
            ],
            table_name: 'patients',
            primary_keyed_column: {
              key: :id
            }
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
        { 'chart_number' => 'B0001', 'first_name' => 'Bugs', 'last_name' => 'Bunny' },
        { 'chart_number' => 'B0002', 'first_name' => 'Babs', 'last_name' => 'Bunny' }
      ]

      expect(actual).to eq(expected)
    end
  end
end
