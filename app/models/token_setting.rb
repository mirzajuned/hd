class TokenSetting
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token_enabled, type: Boolean, default: false
  field :use_incrementor, type: Boolean, default: false
  field :sort_list_by_token, type: Boolean, default: false

  field :used_tokens, type: Hash
  field :used_tokens_date, type: Date, default: Date.current

  belongs_to :facility
end
