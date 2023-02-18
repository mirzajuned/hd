class Inventory::Transaction::StoreConsumption
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  extend SearchType
  extend Enumerize

  field :transaction_date, type: Date

  field :consumption_display_id, type: String

  field :entered_by, type: String
  field :entered_by_id, type: BSON::ObjectId
  field :entry_type, type: String

  field :note, type: String
  field :total_cost, type: Float
  field :adjusted_amount, type: Float
  field :comments, type: String
  field :search_type, type: String

  field :department_name, type: String
  field :department_id, type: String

  field :user_id, type: BSON::ObjectId
  field :store_name, type: BSON::ObjectId
  field :store_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId

  field :cancelled_by_id, type: BSON::ObjectId
  field :cancelled_by_name, type: String
  field :cancelled_on, type: DateTime
  field :approved_by_id, type: BSON::ObjectId
  field :approved_by_name, type: String
  field :approved_on, type: DateTime
  field :status, type: Integer

  enumerize :status,
            in: { open: 0, approved: 1, cancelled: 2, inprocess: 3, completed: 4 },
            default: :open, predicates: true, scope: :having_status
  #eg. having_status => Inventory::Transaction::Transfer.having_status(:inprocess)

  embeds_many :items, class_name: '::Inventory::Transaction::Item'

  accepts_nested_attributes_for :items,
                                reject_if: proc { |attributes| attributes['stock'].blank? },
                                allow_destroy: true

  def self.build(*args)
    refund = new
    refund.items.build(*args)
    refund
  end

  belongs_to :store, optional: true, class_name: '::Inventory::Store'
  belongs_to :approved_by, optional: true, class_name: '::User'

  [:cancelled, :approved].each do |method|
    define_method "set_#{method}" do |user|
      self.update( status: method, "#{method}_by_id": user.id,
        "#{method}_by_name": user.fullname, "#{method}_on": DateTime.now )
    end
  end
end
