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

      CREATED_AT = Burner::Modeling::Attribute.make(
        key: :created_at, transformers: [{ type: NOW_TYPE }]
      )

      UPDATED_AT = Burner::Modeling::Attribute.make(
        key: :updated_at, transformers: [{ type: NOW_TYPE }]
      )

      attr_reader :attribute_renderers, :resolver

      def initialize(resolver:, attributes: [])
        raise ArgumentError, 'resolver is required' unless resolver

        @resolver            = resolver
        @attribute_renderers = make_renderers(attributes)

        freeze
      end

      # Adds the attributes for created_at and updated_at to the currrent attribute renderers.
      def timestamp_created_attribute_renderers
        timestamp_attributes = [CREATED_AT, UPDATED_AT]

        timestamp_attributes.map do |a|
          Burner::Modeling::AttributeRenderer.new(a, resolver)
        end + attribute_renderers
      end

      # Adds the attribute for updated_at to the currrent attribute renderers.
      def timestamp_updated_attribute_renderers
        timestamp_attributes = [UPDATED_AT]

        timestamp_attributes.map do |a|
          Burner::Modeling::AttributeRenderer.new(a, resolver)
        end + attribute_renderers
      end

      def make_renderers(attributes)
        Burner::Modeling::Attribute
          .array(attributes)
          .map { |a| Burner::Modeling::AttributeRenderer.new(a, resolver) }
      end

      def transform(attribute_renderers, row, time)
        attribute_renderers.each_with_object({}) do |attribute_renderer, memo|
          value = attribute_renderer.transform(row, time)

          resolver.set(memo, attribute_renderer.key, value)
        end
      end
    end
  end
end
