# Mongoid MapReduce

Mongoid MapReduce provides simple aggregation functions to your models using MongoDB map/reduce.

[![travis](https://secure.travis-ci.org/jcoene/mongoid-mapreduce.png)](http://travis-ci.org/jcoene/mongoid-mapreduce)

## How simple is simple?

Short answer: very!

There are two map/reduce formulae:

**Aggregates:** Provide a map key and a list of fields to be aggregated via addition.

**Array List:** Provide an array field, the values will be individually aggregated via addition.

## Getting Started

First, add mongoid-mapreduce to your Gemfile:

```ruby
gem 'mongoid-mapreduce'
```

Next, include the module in any models for collections you'll be wanting to map/reduce on:

```ruby
class Employee
  include Mongoid::Document
  include Mongoid::MapReduce

  field :name
  field :division
  field :awards, :type => Integer
  field :age, :type => Integer
  field :male, :type => Integer
  field :rooms, :type => Array
end
```

You can now use the *map_reduce* method on your model to aggregate data using your choice of aggregation formula.

```ruby
# Create a few example employees
Employee.create :name => 'Alan', :division => 'Software', :age => 20, :awards => 5, :male => 1, :rooms => [1,2,3]
Employee.create :name => 'Bob', :division => 'Software', :age => 25, :awards => 4, :male => 1, :rooms => [1,2,3]
Employee.create :name => 'Chris', :division => 'Hardware', :age => 30, :awards => 3, :male => 1, :rooms => [4,5,6]
Employee.create :name => 'Darcy', :division => 'Sales', :age => 35, :awards => 3, :male => 0, :rooms => [1,2,3,4,5,6]

# Aggregate formula (the default): produces 3 records, one for each division.
divs = Employee.map_reduce(:division, :fields => [:age, :awards])
divs.length               # => 3
divs.find('Software').age # => 45
divs['Hardware'].awards   # => 3
divs.first.awards         # => 9
divs.last.age             # => 35
divs.keys                 # => ['Hardware', 'Software', 'Sales']
divs.has_key?('Sales')    # => true
divs.to_hash              # => { "Software" => ..., "Hardware" => ..., "Sales" => ... }

# Array Value formula: produces 6 records, one for each room. Does not take any fields.
rooms = Employee.map_reduce(:rooms, :formula => :array_values)
rooms.length          # => 6
rooms.find(1)._count  # => 3
rooms.counts["5"]     # => 2
rooms.counts          # => { "1" => 3, "2" => 3, "3" => 3, "4" => 2, "5" => 2, "6" => 2 }
```

You can also add Mongoid criteria before the operation:

```ruby
# Produces 2 records, one for each matching division (men only!)
divs = Employee.where(:male => 1).map_reduce(:division, :fields => [:age, :awards])
divs.length               # => 2
divs.has_key?('Sales')    # => false
```

You choose to supply fields as arguments or in a block:

```ruby
# These are the same:
Employee.where(:age.gt => 20).map_reduce(:division, :fields => [:age, :awards])
Employee.where(:age.gt => 20).map_reduce(:division) do
  field :age
  field :awards
end
```

Fields can be of any type supported by Mongoid serialization, and field type is specified in block configuration:

```ruby
divs = Employee.map_reduce(:division) do
  field :age, :type => Integer
  field :awards, :type => Float
end

divs.find('Software').age     # => 60
divs.find('Software').awards  # => 9.0
```

Additional meta fields are included in the results:

NOTE: _key_name and _key_value are discarded when converting to Hash.

```ruby
# Produces 2 records, one for each matching division (men only!)
divs = Employee.map_reduce(:division, :fields => [:age, :awards])
divs.find('Software')._key_name   # => :division
divs.find('Software')._key_value  # => "Software"
divs.find('Software').division    # => "Software" (_key_name => _key_value)
divs.find('Software')._count      # => 2

# You can choose another name for the count field
Employee.map_reduce(:division, :count_field => :num).find('Software').num  #=> 2
```

You can also use javascript as the key if you want some more control over what is emitted by the map function i.e.
This mucks up the returned hash's keys and so the hash keys can be overwritten by passing ```:map_key_as => :category``` and ```:count_field_as => :total``` to specify the desired keys i.e.

Please note - the javascript you add must be enclosed in parenthesis.

```ruby
@docs = DigiDocument.search(:document_type => "receipt")
@docs.map_reduce("(this.categories_array.join(',') + '').length == 0 ? 'none' : this.categories_array.join(',') ", :map_key_as => "category") do
                   field :"receipt ? this.receipt.total : 0", :as => "total"
end
```

## Enhancements and Pull Requests

If you find the project useful but it doesn't meet all of your needs, feel free to fork it and send a pull request.

## License

MIT license, go wild.
