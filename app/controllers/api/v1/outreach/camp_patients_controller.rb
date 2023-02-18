module Api
  module V1
    module Outreach
      class CampPatientsController < ApiApplicationController
        before_action :doorkeeper_authorize!

        def create
          @camp_patient = CampPatient.new(patient_params)
          sub_refferal_id = SubReferralType.find_by(camp_unique_id: params['patient']['camp_username'],
                                                    referral_type_id: 'FS-RT-0006')&.id
          @camp_patient.organisation_id = params['patient']['organisation_id']['$oid']
          @camp_patient.facility_id = params['patient']['facility_id']['$oid']
          @camp_patient.outreach_patient_id = params['patient']['_id']['$oid']
          @camp_patient.sub_referral_type_id = sub_refferal_id
          @camp_patient.save!
          update_patient_served
          render json: { msg: 'success', status: 200 }
        rescue StandardError => e
          #  todo -> raise error in mail
          logger.info ">>>>>>>>>#{e}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          render json: { msg: 'failed to save in ehr', status: 500 }, status: 200
        end

        def update
          @camp_patient = CampPatient.find_by(camp_patient_identifier: params['patient']['camp_patient_identifier'])
          new_params =  params[:patient].as_json.except('_id', 'organisation_id', 'facility_id',
                                                        'camp_user_id', 'outreach_patient_id')
          @camp_patient.update_attributes!(new_params)
          render json: { msg: 'success', status: 200 }, status: 200
        rescue StandardError => e
          #  todo -> raise error in mail
          logger.info ">>>>>>>>>#{e}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          render json: { msg: 'failed to save in ehr', status: 500 }, status: 200
        end

        def facilities
          faci = Organisation.find_by(id: params[:organisation_id]).facilities
          facilities = faci.map { |fac| { id: fac.id.to_s, name: fac.name } }
          render json: { msg: 'success', facilities: facilities, status: 200 }, status: 200
        rescue StandardError => e
          #  todo -> raise error in mail
          logger.info ">>>>>>>>>#{e}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
          render json: { msg: 'failed to fetch', status: 500 }
        end

        def bulk_upload
          # OutreachJobs::SaveBulkPatientsJob.perform_later(params.to_unsafe_hash)
          params['patient_for_bulk_upload'].each do |camp_patient_details|
            params['patient'] = camp_patient_details
            @camp_patient = CampPatient.new(patient_params)
            sub_refferal_id = SubReferralType.find_by(camp_unique_id: params['patient']['camp_username'],referral_type_id: 'FS-RT-0006')&.id
            @camp_patient.organisation_id = params['patient']['organisation_id']['$oid']
            @camp_patient.facility_id = params['patient']['facility_id']['$oid']
            @camp_patient.outreach_patient_id = params['patient']['_id']['$oid']
            @camp_patient.sub_referral_type_id = sub_refferal_id
            @camp_patient.save!
            update_patient_served
          end
          render json: { msg: 'success : Data receieved by EHR', status: 200 }
          rescue StandardError => e
            logger.info ">>>>>>>>>#{e}>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
            render json: { msg: 'failed to save in ehr', status: 500 }, status: 200
        end

        private

        def update_patient_served
          @camp = Camp.find_by(username: params['patient']['camp_username'])
          @camp.update(patient_served: @camp.patient_served + 1) if @camp.present?
        end

        def patient_params
          params.require(:patient).permit(:fullname, :email, :gender, :age, :camp_name, :camp_username,
                                          :commune, :district, :city, :address1, :address2, :phone_number, :complaints,
                                          :visual_acuity_r, :visual_acuity_l, :anetrior_segment_r, :dob,
                                          :temperature, :anetrior_segment_l, :fundus_r, :fundus_l, :iop_r,
                                          :iop_l, :duct_r,
                                          :duct_l, :diagnosis_r, :diagnosis_l, :bp, :us, :pulse, :cvs, :rs, :surgery,
                                          :advice, :rr, :medication, :follow_up_date, :refer_to_facility, :surgery_eye,
                                          :advice_purpose, :camp_patient_identifier, :glass_prescription_r,
                                          :glass_prescription_l, :advice_purpose, :camp_patient_identifier,
                                          :r_glassesprescriptions_distant_sph,
                                          :r_glassesprescriptions_add_sph, :r_glassesprescriptions_near_sph,
                                          :r_glassesprescriptions_distant_cyl,
                                          :r_glassesprescriptions_add_cyl, :r_glassesprescriptions_near_cyl,
                                          :r_glassesprescriptions_distant_axis, :r_glassesprescriptions_add_axis,
                                          :r_glassesprescriptions_near_axis, :r_glassesprescriptions_distant_vision,
                                          :r_glassesprescriptions_add_vision, :r_glassesprescriptions_near_vision,
                                          :l_glassesprescriptions_distant_sph, :l_glassesprescriptions_add_sph,
                                          :l_glassesprescriptions_near_sph, :l_glassesprescriptions_distant_cyl,
                                          :l_glassesprescriptions_add_cyl, :l_glassesprescriptions_near_cyl,
                                          :l_glassesprescriptions_distant_axis, :l_glassesprescriptions_add_axis,
                                          :l_glassesprescriptions_near_axis, :l_glassesprescriptions_distant_vision,
                                          :l_glassesprescriptions_add_vision, :l_glassesprescriptions_near_vision)
        end
      end
    end
  end
end
