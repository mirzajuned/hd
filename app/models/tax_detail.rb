class TaxDetail
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :type, type: String
  field :total, type: Float

  embedded_in :tax_collected
end
