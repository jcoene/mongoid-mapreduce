require "spec_helper"

describe Mongoid::MapReduce do

  before :each do
    @aapl = Company.create :name => 'Apple', :market => 'Technology', :quote => 401.82, :shares => 972_090_000
    @msft = Company.create :name => 'Microsoft', :market => 'Technology', :quote => 25.06, :shares => 8_380_000_000
    @sbux = Company.create :name => 'Starbucks', :market => 'Food', :quote => 38.60, :shares => 746_010_000
    Employee.create :name => 'Alan', :division => 'Software', :age => 30, :awards => 5, :rooms => [1,2], :active => true, :company => @aapl
    Employee.create :name => 'Bob', :division => 'Software', :age => 30, :awards => 4, :rooms => [3,4,5], :active => true, :company => @aapl
    Employee.create :name => 'Chris', :division => 'Hardware', :age => 30, :awards => 3, :rooms => [1,2,3,4], :active => false, :company => @aapl
  end

  describe 'DSL' do

    it 'can be really, really simple' do
      r = Employee.map_reduce
      r.length.should eql 3
    end

    describe 'criteria' do

      it 'can be supplied' do
        r = Employee.where(:name => 'Bob').map_reduce
        r.length.should eql 1
      end

      it 'can be chained' do
        r = Employee.where(:division => 'Software').and(:awards.gt => 4).map_reduce { field :awards }
        r.length.should eql 1
        r.first.awards.should eql 5
      end

    end

    describe 'fields' do

      it 'can be supplied as an argument' do
        r = Employee.map_reduce(:_id, :fields => [:age, :awards])
        r.length.should eql 3
        r.first.keys.should include :age
        r.first.keys.should include :awards
      end

      it 'can be supplied in a block' do
        r = Employee.map_reduce { field :age; field :awards }
        r.first.keys.should include :age
        r.last.keys.should include :awards
      end

      it 'can be integers' do
        r = Employee.map_reduce do
          field :age, type: Integer
        end
        r.first.age.should be_an_instance_of(Fixnum)
      end

      it 'can be floats' do
        r = Company.map_reduce(:market) do
          field :quote, type: Float
          field :shares, type: Integer
        end
        r.first.quote.should be_an_instance_of(Float)
        r.find('Technology').quote.should eql (@aapl.quote + @msft.quote)
        r.find('Food').quote.should eql @sbux.quote
      end

      it 'can be strings' do
        r = Employee.map_reduce(:division) do
          field :age, type: String
        end
        r.first.age.should be_an_instance_of(String)
        r.find('Hardware').age.should eql "30"
        r.find('Software').age.should eql "60"
      end

      it 'can be sourced from an array' do
        r = Employee.map_reduce do
          field :rooms, :type => Integer, :formula => :array_values
        end
        r.length.should eql 5
        r.find(1)._count.should eql 2
        r.counts["5"].should eql 1
      end

    end

    describe 'other options' do

      it 'count field can be renamed' do
        r = Employee.map_reduce(:_id, count_field: :g)
        r.first.keys.should include :g
        r.first.keys.should_not include :_count
      end

    end

  end

  describe 'results' do

    it 'are returned as a Results object' do
      r = Employee.map_reduce
      r.should be_an_instance_of(Mongoid::MapReduce::Results)
    end

    it 'contain multiple Document objects' do
      r = Employee.map_reduce
      r.first.should be_an_instance_of(Mongoid::MapReduce::Document)
    end

    it 'can be found using find or []' do
      r = Employee.map_reduce(:division)
      r.find('Hardware').should be_an_instance_of(Mongoid::MapReduce::Document)
      r['Software'].should be_an_instance_of(Mongoid::MapReduce::Document)
    end

    it 'exposes keys and supplies has_key? method' do
      r = Employee.map_reduce(:division)
      r.keys.should be_an_instance_of(Array)
      r.has_key?('Hardware').should eql true
      r.has_key?('Sales').should eql false
      r.keys.length.should eql 2
      r.keys.should include 'Hardware'
      r.keys.should include 'Software'
    end

    it 'can be converted to a hash' do
      h = Employee.map_reduce(:division, :fields => [:age, :awards]).to_hash
      h['Hardware']['awards'].should eql 3
    end

  end

  describe 'documents' do

    it 'always contain a map key name and value, key => value and count' do
      r = Employee.map_reduce(:division)
      r.first.keys.should include :_key_name
      r.first.keys.should include :_key_value
      r.first[r.first._key_name.to_sym].should eql r.first._key_value
      r.find('Software')._count.should eql 2
      r.find('Hardware')._count.should eql 1
    end

    it 'can be converted to a hash' do
      r = Employee.map_reduce
      r.first.to_hash.should be_an_instance_of(Hash)
    end

  end

  describe 'map-reduce' do

    it 'maps on _id by default' do
      r = Employee.map_reduce
      r.first._key_name.to_s.should eql '_id'
    end

    it 'can be mapped on another key' do
      r = Employee.map_reduce(:division, :fields => [:age, :awards])
      r.length.should eql 2 # Hardware and Software
      r.find('Hardware').age.should eql 30
      r.find('Software').awards.should eql 9
    end

    it 'can process boolean values' do
      r = Employee.map_reduce(:division) do
        field :age, :type => Integer
        field :active, :type => Integer
      end
      p r
      r.find('Software').active.should eql 2
      r.find('Hardware').active.should eql nil
    end

  end

end
