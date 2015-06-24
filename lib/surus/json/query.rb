module Surus
  module JSON
    class Query
      attr_reader :original_scope
      attr_reader :options

      def initialize(original_scope, options={})
        @original_scope = original_scope
        @options = options
      end

      private
      def klass
        original_scope.klass
      end

      def subquery_sql
        if options.key?(:columns) || options.key?(:include)
          select(columns.map(&:to_s).join(', ')).to_sql
        else
          original_scope.to_sql
        end
      end

      def columns
        selected_columns + association_columns
      end

      def table_columns
        klass.columns
      end

      def selected_columns
        if options.key? :columns
          options[:columns]
        else
          table_columns.map do |c|
            "#{quoted_table_name}.#{connection.quote_column_name c.name}"
          end
        end
      end

      def association_columns
        included_associations_name_and_options.map do |association_name, association_options|
          association = klass.reflect_on_association association_name

          # The way to get the association type is different in Rails 4.2 vs 4.0-4.1
          association_type = if defined? ActiveRecord::Reflection::BelongsToReflection
            # Rails 4.2+
            case association
            when ActiveRecord::Reflection::HasOneReflection
              :has_one
            when ActiveRecord::Reflection::BelongsToReflection
              :belongs_to
            when ActiveRecord::Reflection::HasManyReflection
              :has_many
            when ActiveRecord::Reflection::HasAndBelongsToManyReflection
              :has_and_belongs_to_many
            when ActiveRecord::Reflection::ThroughReflection
              :has_many_through
            end
          else
            # Rails 4.0-4.1
            association.source_macro
          end

          subquery = case association_type
          when :belongs_to
            association_scope = BelongsToScopeBuilder.new(original_scope, association).scope
            RowQuery.new(association_scope, association_options).to_sql
          when :has_one
            association_scope = HasOneScopeBuilder.new(original_scope, association).scope
            RowQuery.new(association_scope, association_options).to_sql
          when :has_many
            association_scope = HasManyScopeBuilder.new(original_scope, association).scope
            ArrayAggQuery.new(association_scope, association_options).to_sql
          when :has_and_belongs_to_many
            association_scope = HasAndBelongsToManyScopeBuilder.new(original_scope, association).scope
            ArrayAggQuery.new(association_scope, association_options).to_sql
          when :has_many_through
            association_scope = HasManyThroughScopeBuilder.new(original_scope, association).scope
            ArrayAggQuery.new(association_scope, association_options).to_sql
          end
          "(#{subquery}) #{connection.quote_column_name association_name}"
        end
      end

      def included_associations_name_and_options
        _include = options[:include]
        if _include.nil?
          {}
        elsif _include.kind_of?(::Hash)
          _include
        elsif _include.kind_of?(::Array)
          _include.each_with_object({}) do |e, hash|
            if e.kind_of?(Hash)
              hash.merge!(e)
            else
              hash[e] = {}
            end
          end
        else
          {_include => {}}
        end
      end

      delegate :connection, :quoted_table_name, to: :klass
      delegate :select, to: :original_scope
    end
  end
end
