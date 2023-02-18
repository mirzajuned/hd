class FeedbackQuestionsSet
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :type, type: String
  field :question_field, type: String

  embedded_in :feedback_setting, class_name: "::FeedbackSetting"
end
