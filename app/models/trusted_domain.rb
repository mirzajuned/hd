class TrustedDomain
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String

  field :disabled, type: Boolean, default: false
  field :deleted, type: Boolean, default: false

  field :use_count, type: Integer, default: 0

  belongs_to :organisation

  validates_presence_of :name
  validates_format_of :name, with: /\A[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}\z/,
                             if: ->(attr) { attr.name.present? }
  validates_uniqueness_of :name, scope: [:deleted, :organisation_id]
end
