class Invoice::InventoryInvoiceStateTransition
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic
  include MethodMissing

  field :namespace, type: String
  field :event, type: String
  field :from, type: String
  field :to, type: String
  belongs_to :inventory_invoice, class_name: '::Invoice::InventoryInvoice'

  scope :last_states, lambda { order("created_at desc") }
end
