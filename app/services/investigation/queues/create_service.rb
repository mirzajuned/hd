# USED BY WORKER FOR NOW
module Investigation
  module Queues
    module CreateService
      def self.call(appointment_id, patient, flag, user, facility, datetime)
        appointment = Appointment.find_by(id: appointment_id)
        investigations_queue = Investigation::Queue.find_by(patient_id: patient.id.to_s, facility_id: facility.id, investigation_type: flag)
        organisation = facility.organisation

        if investigations_queue.nil?
          @investigation_queue = Investigation::Queue.new
          @investigation_queue["organisation_id"] = organisation.id
          @investigation_queue["facility_id"] = facility.id
          @investigation_queue["patient_id"] = patient.id
          @investigation_queue["appointment_id"] = appointment_id.to_s
          @investigation_queue["user_id"] = user.id
          @investigation_queue["patient_name"] = patient.fullname
          @investigation_queue["speciality_id"] = appointment.try(:specialty_id)
          @investigation_queue["investigation_type"] = flag
          @investigation_queue["appointment_date"] = datetime
          @investigation_queue["appointment_time"] = datetime
          if @investigation_queue.save!
            return @investigation_queue
          end
        else
          # To Update Status
          status = ""
          investigations = Investigation::InvestigationDetail.where(queue_id: investigations_queue.id.to_s)

          if investigations.pluck(:state).any? { |i| ['performed', 'template_created'].include? i }
            # if one inv is performed submit for review
            status = 'review'
          elsif investigations.pluck(:state).uniq[0] == 'removed' && investigations.pluck(:state).uniq.count == 1 # if all investigations removed mark status completed
            status = 'completed'
          else
            status = 'pending'
          end

          options = { appointment_id: appointment_id.to_s }
          options = options.merge({ is_deleted: false, status: status, status_updated_at: Time.current })

          # To not let Old Appointment Overwrite New
          if investigations_queue.appointment_time < datetime
            options = options.merge({ organisation_id: organisation.id, facility_id: facility.id, user_id: user.id, speciality_id: appointment.try(:specialty_id), appointment_date: datetime, appointment_time: datetime })
          end

          investigations_queue.update(options)
          return investigations_queue
        end
      end
    end
  end
end
