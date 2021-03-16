# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

require 'spec_helper'

describe DbFuel::Modeling::KeyedColumn do
  describe 'KeyedColumn' do
    subject { described_class.make(key: 'primary_key') }

    context 'when key has been set' do
      it 'output key' do
        expect(subject.key).to eq('primary_key')
        expect(subject.column).to eq('primary_key')
      end
    end
  end

  describe 'KeyedColumn' do
    subject { described_class.make(key: 'primary_key', column: 'id') }

    context 'when key and column has been set' do
      it 'output key and column' do
        expect(subject.key).to eq('primary_key')
        expect(subject.column).to eq('id')
      end
    end
  end

  describe 'KeyedColumn' do
    context 'when key has not been set' do
      it 'raises ArgumentError' do
        expect do
          described_class.make(key: nil, column: 'id')
        end.to raise_error(ActsAsHashable::Hashable::HydrationError)
      end
    end
  end
end
