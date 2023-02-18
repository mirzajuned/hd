#require 'celluloid/current'
# class Appointment::Create
#   include Wisper::Publisher
#
#   # def initialize(appointment_id)
#   #   appointment_id = appointment_id
#   # end
#
#   def call(appointment_id)
#     appointment = Appointment.find(appointment_id)
#     organisation = appointment.try(:organisation)
#     facility_setting = FacilitySetting.find_by(facility_id: appointment.try(:facility))
#
#     # Business Logic (Allow Only If Integration True)
#     return if !organisation.try(:integration) || !facility_setting.try(:integration_enabled)
#
#     broadcast("create_#{organisation.try(:publisher_name)}_integration_appointment_data".to_sym, appointment.id)
#   end
# end
