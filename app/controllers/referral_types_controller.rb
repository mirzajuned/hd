class ReferralTypesController < ApplicationController
  before_action :authorize

  def index
    @source = 'referral_index'
    @referral_types = ReferralType.where(is_active: true, is_manageable: true)
    @referral_type_filters = @referral_types.pluck(:name, :id)

    @sub_referral_types = SubReferralType.includes(:referral_type).where(referral_type_id: 'FS-RT-0002', organisation_id: current_user.organisation_id, is_active: true, is_deleted: false).order(updated_at: :desc).limit(10)
  end

  def sub_referral_type
    @sub_referral_type = SubReferralType.where(referral_type_id: params[:referral_type_id], facility_ids: params[:facility_id], is_deleted: false).pluck(:name, :id)
    render json: { 'sub_referral_type': @sub_referral_type }
  end
end
