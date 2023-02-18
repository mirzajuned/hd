module Api
  module V1
    module Ehr
      class PatientDilationsController < ApiApplicationController
        before_action :authorize_token

        before_action :find_appointment, only: [:new, :create, :reset_dilation_timer, :stop_dilation]
        before_action :find_patient_dilation, only: [:reset_dilation_timer, :stop_dilation]

        def new
          # Patient
          @patient = @appointment.patient

          # Facility
          @facility = Facility.find(params[:current_facility_id])

          # Doctors
          @doctors = @facility.users.where(role_ids: 158965000).pluck(:fullname, :id)

          # EyeDrops
          @eye_drops = @appointment.patient.get_drugallergies_list_attribute("dilationdrops")

          # Patient Allergies
          if @patient.present?
            @eyedrop_allergy = @patient.allergy_histories.pluck(:name).map(&:titleize)
          end

          find_all_patient_dilation
        end

        def create
          params[:patient_dilation][:start_time] = Time.current
          @patient_dilation = PatientDilation.new(patient_dilation_params)
          if @patient_dilation.save!

            update_appointment # Update Dilation Fields in Appointment

            find_all_patient_dilation # All Dilation

            message("Success")
          else
            message("Failed")
          end
        end

        def reset_dilation_timer
          if @patient_dilation.present?
            if @patient_dilation.update(is_reseted: true, start_time: nil, end_time: nil)

              find_all_patient_dilation # All Dilation

              @patient_dilation = @patient_dilation_list[-1] # Take last Dilation with start_time Present

              update_appointment # Update Dilation Fields in Appointment

              message("Success")
            else
              message("Failed")
            end
          else
            message("Failed")
          end
        end

        def stop_dilation
          if @patient_dilation.present?
            if @patient_dilation.start_time.present?
              if @patient_dilation.update_attributes(end_time: Time.current)

                update_appointment # Update Dilation Fields in Appointment

                find_all_patient_dilation

                message("Success")
              else
                message("Failed")
              end
            else
              message("Failed")
            end
          else
            message("Failed")
          end
        end

        private

        def patient_dilation_params
          params.require(:patient_dilation).permit(:user_id, :appointment_id, :patient_id, :start_time, :drops, :advised_by, :dilated_by, :comment)
        end

        def find_appointment
          @appointment = Appointment.find_by(id: params[:appointment_id])
        end

        def find_patient_dilation
          @patient_dilation = PatientDilation.find_by(id: params[:patient_dilation_id])
        end

        def find_all_patient_dilation
          @patient_dilation_list = PatientDilation.where(appointment_id: @appointment.id.to_s, is_reseted: false).order(start_time: :desc)
          @last_dilation = @patient_dilation_list[0]
        end

        def update_appointment
          @appointment.update(dilation_start_time: @patient_dilation.try(:start_time), dilation_end_time: @patient_dilation.try(:end_time))
        end

        def message(status)
          @message = status
        end
      end
    end
  end
end
