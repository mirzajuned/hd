class User::Vacation
  include Mongoid::Document
  include Mongoid::Timestamps

  field :title, type: String # vacation title
  field :start_time, type: DateTime
  field :end_time, type: DateTime

  belongs_to :user, class_name: "::User"
end
