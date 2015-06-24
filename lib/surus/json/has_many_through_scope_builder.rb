module Surus
  module JSON
    class HasManyThroughScopeBuilder < AssociationScopeBuilder
      def scope
        case association
        when ActiveRecord::Reflection::HasOneReflection
          return HasOneScopeBuilder.new(outside_scope, association).scope
        when ActiveRecord::Reflection::BelongsToReflection
          return BelongsToScopeBuilder.new(outside_scope, association).scope
        when ActiveRecord::Reflection::HasManyReflection
          return HasManyScopeBuilder.new(outside_scope, association).scope
        when ActiveRecord::Reflection::HasAndBelongsToManyReflection
          return HasAndBelongsToManyScopeBuilder.new(outside_scope, association).scope
        when ActiveRecord::Reflection::ThroughReflection
          return HasManyThroughScopeBuilder.new(outside_scope, association.source_reflection).scope
        end
        # binding.pry
        # # s = association
        # #   .klass
        # #   .where("#{outside_primary_key}=#{association_foreign_key}")
        # s = s.instance_eval(&association.scope) if association.scope
        # s
      end

      def outside_primary_key
        "#{outside_class.quoted_table_name}.#{connection.quote_column_name association.active_record_primary_key}"
      end

      def association_foreign_key
        "#{connection.quote_column_name association.foreign_key}"
      end
    end
  end
end
