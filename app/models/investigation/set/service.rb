class Investigation::Set::Service
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :service_name, type: String
  field :service_type, type: String # lab,opthal,radio
  field :service_code, type: String
  field :service_code_type, type: String # loinc,snomed
  field :is_active, type: Boolean, default: false
  field :department_id, type: BSON::ObjectId
  embeds_many :items, class_name: '::Investigation::Set::Service::Item'

  belongs_to :facility
  belongs_to :organisation
  belongs_to :user

  validates :service_name, uniqueness: true, if: :name_unique_within_facility

  def name_unique_within_facility
    @investigation_set_service = Investigation::Set::Service.find_by(facility_id: facility_id, service_name: service_name).present?
  end
end
