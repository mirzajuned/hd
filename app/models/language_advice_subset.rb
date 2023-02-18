class LanguageAdviceSubset
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
  field :language, type: String
  field :content, type: String
  field :lcid_code, type: String
  embedded_in :advice_set, class_name: '::AdviceSet'
end
