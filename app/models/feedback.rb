class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :salutation, type: String
  field :fullname, type: String

  field :mobilenumber, type: String
  field :email, type: String

  field :address_1, type: String
  field :address_2, type: String

  field :age, type: Integer
  field :dobyear, type: String

  field :city, type: String
  field :state, type: String

  # field :registration_counter_rating, type: String
  # field :doctor_rating, type: String
  # field :staff_rating, type: String
  # field :pharmacy_rating, type: String
  # field :hygene_rating, type: String
  #

  field :rating1, type: String
  field :rating2, type: String
  field :rating3, type: String
  field :rating4, type: String
  field :rating5, type: String
  field :rating6, type: String
  field :rating7, type: String
  field :referral_rating, type: String
  field :referral_rating_comment, type: String

  field :average_rating, type: Float, default: 0.00

  field :feedback_note, type: String

  field :type, type: String # patient, visitor or relative

  field :is_patient, type: Boolean, default: false

  field :patient_id, type: BSON::ObjectId
  field :facility_id, type: BSON::ObjectId
  field :organisation_id, type: BSON::ObjectId
  field :user_id, type: BSON::ObjectId
  field :doctor_id, type: BSON::ObjectId
  embeds_many :feedback_question_sets, class_name: "::FeedbackQuestionsSet" # FeedbackQuestionsSet

  field :is_migrated, type: Boolean, default: true
end
