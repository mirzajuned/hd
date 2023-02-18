class ReferringDoctor
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :name, type: String
  field :speciality, type: String
  field :hospital_name, type: String
  field :mobile_number, type: String
  field :email, type: String
  field :address, type: String
  field :city, type: String
  field :state, type: String
  field :pincode, type: String
  field :is_active, type: Boolean, default: true

  belongs_to :user, optional: true
  has_many :patient
  belongs_to :facility, optional: true
  belongs_to :organisation, optional: true
  # validates :name, :presence => {:message => '* Name cannot be blank.'}
  # validates :mobile_number,:numericality => true,:length => { :minimum => 10, :maximum => 10, message: '* Phone No. should be 10 digits' }
  # validates :email,:format => { with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, message: '* Please enter a valid email'}
end
