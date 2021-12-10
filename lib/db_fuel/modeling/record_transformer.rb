# frozen_string_literal: true

#
# Copyright (c) 2020-present, Blue Marble Payroll, LLC
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.
#

module DbFuel
  module Modeling
    # Creates attribute renderers based on attributes passed.
    # Also constains methods to transform attribute renderers
    # and include timestamp attributes if needed.
    class RecordTransformer # :nodoc:
      NOW_TYPE   = 'r/value/now'
      CREATED_AT = 'created_at'
      UPDATED_AT = 'updated_at'

      attr_reader :attribute_renderers, :resolver

      def initialize(resolver:, attributes: [])
        raise ArgumentError, 'resolver is required' unless resolver

        @resolver            = resolver
        @attribute_renderers = make_renderers(attributes)

        freeze
      end

      def transform(row, time, keys: Set.new, created_at: false, updated_at: false)
        dynamic_attributes, all_keys = make_dynamic_attributes(
          keys: keys,
          created_at: created_at,
          updated_at: updated_at
        )

        dynamic_attributes.each_with_object({}) do |attribute_renderer, memo|
          next if all_keys.any? && all_keys.exclude?(attribute_renderer.key)

          value = attribute_renderer.transform(row, time)

          resolver.set(memo, attribute_renderer.key, value)
        end
      end

      private

      def make_dynamic_attributes(keys:, created_at:, updated_at:)
        dynamic_attributes = attribute_renderers
        all_keys           = keys

        if created_at
          dynamic_attributes += [
            Burner::Modeling::AttributeRenderer.new(created_at_timestamp_attribute, resolver)
          ]

          all_keys += [CREATED_AT] if keys.any?
        end

        if updated_at
          dynamic_attributes += [
            Burner::Modeling::AttributeRenderer.new(updated_at_timestamp_attribute, resolver)
          ]

          all_keys += [UPDATED_AT] if keys.any?
        end

        [
          dynamic_attributes,
          all_keys
        ]
      end

      def make_renderers(attributes)
        Burner::Modeling::Attribute
          .array(attributes)
          .map { |a| Burner::Modeling::AttributeRenderer.new(a, resolver) }
      end

      def created_at_timestamp_attribute
        timestamp_attribute(CREATED_AT)
      end

      def updated_at_timestamp_attribute
        timestamp_attribute(UPDATED_AT)
      end

      def timestamp_attribute(key)
        Burner::Modeling::Attribute.make(
          key: key,
          transformers: [
            { type: NOW_TYPE }
          ]
        )
      end
    end
  end
end
