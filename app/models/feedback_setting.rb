class FeedbackSetting
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :organisation_id, type: BSON::ObjectId
  field :set_type, type: String
  field :opd_feedback_feature, type: Boolean, default: false
  field :discharge_feedback_feature, type: Boolean, default: false

  belongs_to :organisation

  embeds_many :feedback_question_sets, class_name: "::FeedbackQuestionsSet" # FeedbackQuestionsSet
  accepts_nested_attributes_for :feedback_question_sets, reject_if: proc { |attributes| attributes['question_field'].blank? }, allow_destroy: true
end
