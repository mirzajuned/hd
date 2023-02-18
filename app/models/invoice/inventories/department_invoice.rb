class Invoice::Inventories::DepartmentInvoice < Invoice
  include Mongoid::Document
  include Mongoid::Timestamps

  field :recipient, type: String
  # field :current_depa
  field :note, type: String

  belongs_to :current_department, class_name: "::Inventory::Department"
  belongs_to :facility, class_name: "::Facility"
  belongs_to :organisation, class_name: "::Organisation"

  embeds_many :items, class_name: "::Invoice::Inventories::Item"
  scope :newest_log_first, lambda { order("created_at DESC") }
end
