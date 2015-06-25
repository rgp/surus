module Surus
  module JSON
    class HasManyThroughScopeBuilder < AssociationScopeBuilder
      def scope
        raise "Inverse Needed for #{association.name}" unless association.inverse_of
        s = association
          .klass
          .joins(association.inverse_of.name)
        s = s.where(join_table_name(s) => outside_scope.where_values_hash)
        s = s.instance_eval(&association.scope) if association.scope
        s
        # s = association.delegate_reflection.association_scope_cache(connection,nil).query_builder.sql_for([],nil)
        # s.gsub!(/\$1/,outside_primary_key)
        # "select array_to_json(coalesce(array_agg(row_to_json(t)), '{}')) from (#{s}) t"
      end

      def join_table_name(s)
        return outside_scope.table.name unless association.klass == association.inverse_of.klass
        (s.joins_values + [s.table.name]).join "_"
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
