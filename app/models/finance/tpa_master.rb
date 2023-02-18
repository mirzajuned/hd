class Finance::TpaMaster
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String                         #Display Name
  field :description, type: String
  field :last_edited_by, type: String
  field :is_disable, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId


  embeds_many :corporate_details, class_name: '::Finance::TpaMaster::CorporateDetail'

  accepts_nested_attributes_for :corporate_details,
                                reject_if: proc { |attributes| attributes['insurance_master_id'].blank? ||
                                    attributes['corporate_master_id'].blank?  },
                                allow_destroy: true


  def self.build(*args)
    tpa_master = new
    tpa_master.corporate_details.build(*args)
    tpa_master
  end

end
