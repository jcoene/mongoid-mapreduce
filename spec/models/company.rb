class Company
  include Mongoid::Document
  include Mongoid::MapReduce

  field :name, type: String
  field :market, type: String
  field :shares, type: Integer
  field :quote, type: Float

  has_many :employees
end
