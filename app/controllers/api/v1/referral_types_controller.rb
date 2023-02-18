module Api
  module V1
    class ReferralTypesController < ApiApplicationController
      def sub_referral_type
        @sub_referral_types = SubReferralType.where(referral_type_id: params[:referral_type_id], facility_ids: params[:current_facility_id], is_deleted: false).pluck(:name, :id)
      end
    end
  end
end
