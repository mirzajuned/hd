class Investigation::Set::Service::Item
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :item_name, type: String
  field :item_normal_range, type: String
  field :item_type, type: String
  field :item_code, type: String
  field :item_code_type, type: String
  field :is_active, type: Boolean, default: false
  belongs_to :facility
  belongs_to :organisation
  belongs_to :user

  embedded_in :service, class_name: '::Investigation::Set::Service'
end
