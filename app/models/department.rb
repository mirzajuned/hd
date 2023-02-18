class Department
  include Mongoid::Document
  include Mongoid::Timestamps

  attr_accessor :migration

  field :name, type: String
  field :is_launched, type: Boolean, default: false

  field :display_name, type: String

  field :order, type: Integer

  has_many :users

  validates_uniqueness_of :order

  before_save :check_order, unless: :migration

  def check_order
    unless order.present?
      department_id = id.to_s
      max_order = Department.max("order") + 1 rescue 5
      if department_id == '485396012' #opd
        order = 1
      elsif department_id == '486546481' #ipd
        order = 2
      elsif department_id == '50121007' #optical
        order = 3
      elsif department_id == '284748001' #pharmacy
        order = 4
      else
        order = max_order
      end
      order
    end
  end
end
