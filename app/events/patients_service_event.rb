require 'ventable'

class PatientsServiceEvent
  include Ventable::Event

  attr_accessor :patient_id, :user_id, :description, :type

  def initialize(patient_id, user_id, description, type)
    @patient_id = patient_id
    @user_id = user_id
    @description = description
    @type = type
  end
end
