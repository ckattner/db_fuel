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
    class AttributeRendererSet # :nodoc:
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

      # Adds the attributes for created_at and updated_at to the currrent attribute renderers.
      def timestamp_created_attribute_renderers
        timestamp_attributes = [created_at_timestamp_attribute, updated_at_timestamp_attribute]

        timestamp_attributes.map do |a|
          Burner::Modeling::AttributeRenderer.new(a, resolver)
        end + attribute_renderers
      end

      # Adds the attribute for updated_at to the currrent attribute renderers.
      def timestamp_updated_attribute_renderers
        timestamp_attributes = [updated_at_timestamp_attribute]

        timestamp_attributes.map do |a|
          Burner::Modeling::AttributeRenderer.new(a, resolver)
        end + attribute_renderers
      end

      def make_renderers(attributes)
        Burner::Modeling::Attribute
          .array(attributes)
          .map { |a| Burner::Modeling::AttributeRenderer.new(a, resolver) }
      end

      def transform(attribute_renderers, row, time, keys = Set.new)
        attribute_renderers.each_with_object({}) do |attribute_renderer, memo|
          next if keys.any? && keys.exclude?(attribute_renderer.key)

          value = attribute_renderer.transform(row, time)

          resolver.set(memo, attribute_renderer.key, value)
        end
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
