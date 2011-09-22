class Company
  include Mongoid::Document
  include Mongoid::MapReduce

  field :name

  has_many :employees
end
