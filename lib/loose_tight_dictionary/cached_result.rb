class LooseTightDictionary
  class CachedResult < ::ActiveRecord::Base
    set_table_name :loose_tight_dictionary_cached_results
    
    def self.create_table
      connection.create_table :loose_tight_dictionary_cached_results do |t|
        t.string :a_class
        t.string :a
        t.string :b_class
        t.string :b
      end
      connection.add_index :loose_tight_dictionary_cached_results, [:a_class, :b_class, :a], :name => 'aba'
      connection.add_index :loose_tight_dictionary_cached_results, [:a_class, :b_class, :b], :name => 'abb'
      connection.add_index :loose_tight_dictionary_cached_results, [:a_class, :b_class, :a, :b], :name => 'abab'
      reset_column_information
    end
    
    def self.setup(from_scratch = false)
      connection.drop_table :loose_tight_dictionary_cached_results if from_scratch and table_exists?
      create_table unless table_exists?
    end
    
    module ActiveRecordBaseExtension
      # required options:
      # :primary_key - what to call on this class
      # :foreign_key - what to call on the other class
      def cache_loose_tight_dictionary_matches_with(other_active_record_class, options)
        other = other_active_record_class.to_s.singularize.camelcase
        me = name
        if me < other
          a = me
          b = other
          primary_key = :a
          foreign_key = :b
        else
          a = other
          b = me
          primary_key = :b
          foreign_key = :a
        end

        # def aircraft
        define_method other.underscore.pluralize do
          other.constantize.where options[:foreign_key] => send("#{other.underscore.pluralize}_foreign_keys")
        end
  
        # def flight_segments_foreign_keys
        define_method "#{other.underscore.pluralize}_foreign_keys" do
          fz = ::LooseTightDictionary::CachedResult.arel_table
          sql = fz.project(fz[foreign_key]).where(fz["#{primary_key}_class".to_sym].eq(self.class.name).and(fz["#{foreign_key}_class".to_sym].eq(other)).and(fz[primary_key].eq(send(options[:primary_key])))).to_sql
          connection.select_values sql
        end
  
        # def cache_aircraft!
        define_method "cache_#{other.underscore.pluralize}!" do
          other_class = other.constantize
          primary_key_value = send options[:primary_key]
          other_class.loose_tight_dictionary.find_all(primary_key_value).each do |other_instance|
            attrs = {}
            attrs[primary_key] = primary_key_value
            attrs["#{primary_key}_class"] = self.class.name
            attrs[foreign_key] = other_instance.send options[:foreign_key]
            attrs["#{foreign_key}_class"] = other
            unless ::LooseTightDictionary::CachedResult.exists? attrs
              ::LooseTightDictionary::CachedResult.create! attrs
            end
          end
        end
      end
    end
  end
end

::ActiveRecord::Base.extend ::LooseTightDictionary::CachedResult::ActiveRecordBaseExtension
