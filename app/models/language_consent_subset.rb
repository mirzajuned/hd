class LanguageConsentSubset
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :language, type: String
  field :content, type: String

  embedded_in :custom_consent
end
