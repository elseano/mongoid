class Rating
  include Mongoid::Document
  
  field :rating, :type => Integer, :default => 0
  
  referenced_in :ratable, :polymorphic => true
  referenced_in :person
end