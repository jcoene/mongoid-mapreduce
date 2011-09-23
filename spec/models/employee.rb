class Employee
  include Mongoid::Document
  include Mongoid::MapReduce

  field :name
  field :division
  field :awards, :type => Integer
  field :age, :type => Integer
  field :rooms, :type => Array

  belongs_to :company
end
