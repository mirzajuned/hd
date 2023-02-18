class Camp
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :camp_name, type: String
  field :username, type: String
  field :email, type: String
  field :created_by, type: String
  field :password, type: String
  field :camp_location, type: String
  field :patient_served, type: Integer, default: 0 # todo-> update camp 0 in all persisting patient served
  field :status, type: String
  # info
  field :camp_type, type: String
  field :contact_person, type: String
  field :contact_no, type: String
  field :country, type: String
  field :state, type: String
  field :city, type: String
  field :pincode, type: String
  field :district, type: String
  field :commune, type: String
  field :area, type: String
  field :venue, type: String
  field :days, type: Integer
  field :expected_outpatients, type: Integer
  field :expected_surgeries, type: Integer
  field :camp_date, type: Date
  field :review_camp_applicable, type: Boolean, default: false
  field :review_date, type: Date
  field :review_camp_venue, type: String
  field :co_sponsors, type: Array, default: []
  field :is_active, type: Boolean, default: true

  belongs_to :facility

  validates_uniqueness_of :username, message: 'username already taken'
  validates_presence_of :facility_id, message: 'facility_id cannot be blank.'
  validates_presence_of :username, message: 'username cannot be blank'
  validates_presence_of :organisation_id, message: 'organisation_id cannot be blank.'
  validates :password, :presence => { message: 'Please choose a strong password' },
                       :format => { :with => /\A(?=.*[A-Z])(?=.*[0-9])(?=.*[@#$%^&+=]).{8,}\z/, message: 'Must be at least 8 characters and include one number,one Capital letter and any of the following special characters @#$%^&+=' },
                       :confirmation => { message: 'Passwords Do not Match' },
                       :allow_nil => true

  after_update :update_camp_in_patients, if: ->(obj) { camp_attributes_changed(obj) }

  def facility
    facilityname = Facility.find_by(id: facility_id).name
  end

  def camp_attributes_changed obj
    obj.camp_name_changed?
  end

  def update_camp_in_patients
    OutreachJobs::UpdateCamppatientsJob.perform_later(id.to_s)
  end
end
