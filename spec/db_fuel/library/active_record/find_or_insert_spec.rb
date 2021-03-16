# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Library::ActiveRecord::FindOrInsert do
  before(:each) do
    load_data
  end

  let(:output)   { make_burner_output }
  let(:register) { 'register_a' }
  let(:debug)    { false }

  let(:config) do
    {
      name: 'test_job',
      register: register,
      debug: debug,
      attributes: [
        { key: :chart_number },
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
      # Should be finds based on chart_number
      { 'chart_number' => 'C0001', 'first_name' => 'BOZZY',  'last_name' => 'CLOWNZY' },
      { 'chart_number' => 'R0001', 'first_name' => 'FRANKY', 'last_name' => 'RIZZY' },

      # Should be inserts based on chart_number
      { 'chart_number' => 'G0001', 'first_name' => 'HAPPY',  'last_name' => 'GILMORE' },
      { 'chart_number' => 'M0001', 'first_name' => 'BILLY',  'last_name' => 'MADISON' }
    ]
  end

  let(:payload) do
    Burner::Payload.new(
      registers: {
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

    it 'inserts new records' do
      actual = Patient
               .order(:chart_number)
               .select(:chart_number, :first_name, :last_name)
               .as_json(except: :id)

      expected = [
        { 'chart_number' => 'B0001', 'first_name' => 'Bugs', 'last_name' => 'Bunny' },
        { 'chart_number' => 'C0001', 'first_name' => 'Bozo', 'last_name' => 'Clown' },
        { 'chart_number' => 'G0001', 'first_name' => 'HAPPY', 'last_name' => 'GILMORE' },
        { 'chart_number' => 'M0001', 'first_name' => 'BILLY', 'last_name' => 'MADISON' },
        { 'chart_number' => 'R0001', 'first_name' => 'Frank', 'last_name' => 'Rizzo' }
      ]

      expect(actual.count).to eq(5)
      expect(actual).to       eq(expected)
    end

    it 'outputs total existed count' do
      expect(output.outs.first.string).to include('Total Existed: 2')
    end

    it 'outputs total inserted count' do
      expect(output.outs.first.string).to include('Total Inserted: 2')
    end

    it 'sets primary_keyed_column for all payload objects' do
      payload[register].each do |object|
        expected = Patient.find_by(chart_number: object['chart_number']).id
        actual   = object['id']

        expect(actual).to eq(expected)
      end
    end

    context 'when debug is true' do
      let(:debug) { true }

      it 'outputs find sql' do
        expect(written).to include('Find Statement: SELECT')
      end

      it 'outputs existing record' do
        expect(written).to include('Record Exists: {')
      end
    end
  end
end
