# Mongoid MapReduce

Mongoid MapReduce provides simple aggregation functions to your models using MongoDB map/reduce.

[![travis](https://secure.travis-ci.org/jcoene/mongoid-mapreduce.png)](http://travis-ci.org/jcoene/mongoid-mapreduce)

## How simple is simple?

Very. You provide a Mongoid model, criteria, map key and a list of fields to be aggregated. It returns a list of results (one per unique map key value).

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
end
```

You can now use the *map_reduce* method on your model to aggregate data:

```ruby
# Create a few example employees
Employee.create :name => 'Alan', :division => 'Software', :age => 20, :awards => 5, :male => 1
Employee.create :name => 'Bob', :division => 'Software', :age => 25, :awards => 4, :male => 1
Employee.create :name => 'Chris', :division => 'Hardware', :age => 30, :awards => 3, :male => 1
Employee.create :name => 'Darcy', :division => 'Sales', :age => 35, :awards => 3, :male => 0

# Produces 3 records, one for each division.
divs = Employee.map_reduce(:division, :fields => [:age, :awards])
divs.length               # => 3
divs.find('Software').age # => 45
divs['Hardware'].awards   # => 3
divs.first.awards         # => 9
divs.last.age             # => 35
divs.keys                 # => ['Hardware', 'Software', 'Sales']
divs.has_key?('Sales')    # => true
divs.to_hash              # => { "Software" => ..., "Hardware" => ..., "Sales" => ... }
```

You can also add Mongoid criteria before the operation:

```ruby
# Produces 2 records, one for each matching division (men only!)
divs = Employee.where(:male => 1).map_reduce(:division, :fields => [:age, :awards])
divs.length               # => 2
divs.has_key?('Sales')    # => false
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

You can also choose to supply fields in a block:

```ruby
Employee.where(:age.gt => 20).map_reduce(:division) do
  field :age
  field :awards
end
```

## Enhancements and Pull Requests

If you find the project useful but it doesn't meet all of your needs, feel free to fork it and send a pull request.

## License

MIT license, go wild.
