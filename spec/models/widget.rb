class Widget
  include Mongoid::Document
  
  field :name
  referenced_in :owner, :polymorphic => true
end