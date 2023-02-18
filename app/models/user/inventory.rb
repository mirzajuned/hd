class User::Inventory
  include Mongoid::Document

  field :department_id, type: String
  field :current, type: Mongoid::Boolean, default: false

  embedded_in :user, class_name: "::User"
end
