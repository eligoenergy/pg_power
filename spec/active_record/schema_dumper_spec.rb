require 'spec_helper'

describe ActiveRecord::SchemaDumper do

  describe '.dump' do
    before(:all) do
      stream = StringIO.new
      ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, stream)
      @dump = stream.string
    end

    context 'Schemas' do
      it 'dumps schemas' do
        @dump.should =~ /create_schema "demography"/
        @dump.should =~ /create_schema "later"/
        @dump.should =~ /create_schema "latest"/
      end
      it 'dumps schemas in alphabetical order' do
        @dump.should =~ /create_schema "demography".*create_schema "later".*create_schema "latest"/m
      end
    end
    
    context 'Views' do
      it 'dumps views' do
        @dump.should =~ /create_view "demography.citizens_view", "SELECT citizens.id, citizens.country_id, citizens.user_id, citizens.first_name, citizens.last_name, citizens.birthday, citizens.bio, citizens.created_at, citizens.updated_at, citizens.active FROM demography.citizens;"/
      end
    end

    context "Extensions" do
      it 'dumps loaded extension modules' do
        @dump.should =~ /create_extension "fuzzystrmatch", :version => "\d+\.\d+"/
        @dump.should =~ /create_extension "btree_gist", :schema_name => "demography", :version => "\d+\.\d+"/
      end
    end

    context 'Tables' do
      it 'dumps tables' do
        @dump.should =~ /create_table "users"/
      end

      it 'dumps tables from non-public schemas' do
        @dump.should =~ /create_table "demography.citizens"/
      end
    end

    context 'Indexes' do
      it 'dumps indexes' do
        # added via standard add_index
        @dump.should =~ /add_index "users", \["name"\]/
        # added via foreign key
        @dump.should =~ /add_index "pets", \["user_id"\]/
        # foreign key :exclude_index
        @dump.should_not =~ /add_index "demography\.citizens", \["user_id"\]/
        # partial index
        @dump.should =~ /add_index "demography.citizens", \["country_id", "user_id"\].*:where => "active"/
      end

      # This index is added via add_foreign_key
      it 'dumps indexes from non-public schemas' do
        @dump.should =~ /add_index "demography.cities", \["country_id"\]/
      end

      it 'dumps functional indexes' do
        @dump.should =~ /add_index "pets", \["lower\(name\)"\]/
      end

      it 'dumps partial functional indexes' do
        @dump.should =~ /add_index "pets", \["upper\(color\)"\].*:where => "\(name IS NULL\)"/
      end

      it 'dumps indexes with non default access method' do
        @dump.should =~ Regexp.new(Regexp.quote('add_index "pets", ["user_id"], :name => "index_pets_on_user_id_gist", :using => "gist"'))
      end

      it 'dumps indexes with non default access method and multiple args' do
        @dump.should =~ Regexp.new(Regexp.quote('add_index "pets", ["to_tsvector(\'english\'::regconfig, name)"], :name => "index_pets_on_to_tsvector_name_gist", :using => "gist"'))
      end
    end

    context 'Foreign keys' do
      it 'dumps foreign keys' do
        @dump.should =~ /^\s*add_foreign_key "pets", "public.users", :name => "pets_user_id_fk"/
      end

      it 'dumps foreign keys from non-public schemas' do
        @dump.should =~ /^\s*add_foreign_key "demography.citizens", "public.users", :name => "demography_citizens_user_id_fk"/
        @dump.should =~ /add_foreign_key "demography.cities", "demography.countries"/
      end
    end

    context 'Comments' do
      it 'dumps table comments' do
        @dump.should =~ /set_table_comment 'users', 'Information about users'/
      end

      it 'dumps table comments from non-public schemas' do
        @dump.should =~ /set_table_comment 'demography.citizens', 'Citizens Info'/
      end

      it 'dumps column comments' do
        @dump.should =~ /set_column_comment 'users', 'name', 'User name'/
      end

      it 'dumps column comments from non-public schemas' do
        @dump.should =~ /set_column_comment 'demography.citizens', 'first_name', 'First name'/
      end

      it 'dumps index comments' do
        @dump.should =~ /set_index_comment 'index_pets_on_to_tsvector_name_gist', 'Functional index on name'/
      end

      it 'dumps index comments from non-public schemas' do
        @dump.should =~/set_index_comment 'demography.index_demography_citizens_on_country_id_and_user_id', 'Unique index on active citizens'/
      end
    end

  end
end
