module Api
  module V1
    class SubReferralTypesController < ApiApplicationController
      def create
        @sub_referral_type = SubReferralType.new(sub_referral_type_params)
        if @sub_referral_type.save
          @status = "referral saved"
        else
          @status = "referral save failed"
        end
        @sub_referral_types = SubReferralType.where(referral_type_id: params[:referral_type_id], facility_ids: params[:current_facility_id], is_deleted: false).pluck(:name, :id)
      end

      private

      def sub_referral_type_params
        params.permit(:name, :comment, :is_active, :is_deleted, :speciality, :designation, :existing_patient, :relation, :campaign_type, :camp_date, :department, :agency_name, :location, :city, :state, :mobile_number, :email, :search, :referral_type_id, :user_id, :organisation_id, facility_ids: [])
      end
    end
  end
end
