module Reports
  module Ipd
    class Admissions
      def initialize(admission)
        @admission = admission
      end

      def call
        @admission_count = Admission.where(:admissiondate => @admission.admissiondate, user_id: @admission.user_id, facility_id: @admission.facility_id).count
        @patient_admission = DailyReport.find_by(date: Date.current, facility_id: @admission.facility_id.to_s, specialty_id: @admission.specialty_id)

        if @patient_admission.blank?
          DailyReport.create(create_params)
        else
          @patient_admission.update_attributes(update_params)
        end
      end

      private

      def create_params
        {
          user_id: @admission.doctor,
          date: @admission.admissiondate,
          admission_count: @admission_count,
          month: @admission.admissiondate.month,
          year: @admission.admissiondate.year,
          organisation_id: @admission.user.organisation_id.to_s,
          facility_id: @admission.facility_id.to_s,
          specialty_id: @admission.specialty_id.to_s
        }
      end

      def update_params
        {
          admission_count: @admission_count,
          facility_id: @admission.facility_id.to_s
        }
      end

      # Logic to calculate New Old Patient , not required for now
      #   def new_old_patient_in_ipd
      # ipd_patient_ids = Admission.where(user_id: current_user.id,admissiondate: Date.current,facility_id: @admission.facility_id).pluck(:patient_id)
      # ipd_new_patient_count = 0
      # ipd_old_patient_count = 0
      # ipd_patient_ids.each do |pat_id|
      #   pat=Patient.find_by(id: pat_id)
      #   if pat.created_at.to_date == Date.current
      #     ipd_new_patient_count = ipd_new_patient_count+1
      #   else
      #     ipd_old_patient_count = ipd_old_patient_count+1
      #   end
      # end
      # end
    end
  end
end
