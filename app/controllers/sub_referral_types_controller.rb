class SubReferralTypesController < ApplicationController
  before_action :authorize
  before_action :find_sub_referral_type, only: [:edit, :update, :destroy]
  before_action :find_sub_referral_types, only: [:create, :update, :destroy]
  before_action :find_more_referrals, only: [:show_more_referrals]

  def new
    @facilities = current_user.facilities.where(is_active: true)
    @sub_referral_type = SubReferralType.new

    if params[:location].nil? # Created from Setting
      @referral_types = ReferralType.where(is_active: true, is_manageable: true)
    else # Created from Appointment
      @referral_type = ReferralType.find_by(id: params[:referral_type_id])
      respond_to do |format|
        format.js { render 'new_sub_referral.js.erb' }
      end
    end
  end

  def create
    @source = 'referral_index'
    @sub_referral_type = SubReferralType.new(sub_referral_type_params)
    if @sub_referral_type.save
      respond_refresh
    else
      render 'new'
    end
  end

  def edit
    @facilities = current_user.facilities.where(is_active: true)
  end

  def update
    @source = 'referral_index'
    if @sub_referral_type.update_attributes(sub_referral_type_params)
      respond_refresh
    else
      render 'edit'
    end
  end

  def destroy
    @sub_referral_type.update!(is_deleted: true)
    respond_refresh
  end

  def form
    @label = params[:label]
  end

  def search_filter
    @source = 'referral_index'
    r_query = params[:search].to_s.split(' ').join('.*')

    options = { referral_type_id: params[:referral_type_id], organisation_id: current_user.organisation_id,
                is_active: true, is_deleted: false }
    options = options.merge(name: /^#{Regexp.escape(r_query)}/i) if params[:referral_type_id].present? && r_query.length > 3

    @sub_referral_types = SubReferralType.includes(:referral_type).where(options).order(updated_at: :desc).limit(10)

    respond_refresh
  end

  def show_more_referrals
    @source = 'show_more'

    respond_to do |format|
      format.js { render 'show_more_referrals' }
    end
  end

  private

  def sub_referral_type_params
    params.require(:sub_referral_type).permit(
      :name, :comment, :is_active, :is_deleted, :speciality, :designation, :existing_patient, :relation, :campaign_type,
      :camp_date, :department, :agency_name, :location, :city, :state, :mobile_number, :email, :search,
      :referral_type_id, :user_id, :organisation_id, facility_ids: []
    )
  end

  def find_sub_referral_type
    @sub_referral_type = SubReferralType.find_by(id: params[:id])
  end

  def find_sub_referral_types
    referral_type_id = @sub_referral_type&.referral_type_id ||
                       params[:referral_type_id] ||
                       params[:sub_referral_type][:referral_type_id]

    @sub_referral_types = SubReferralType.includes(:referral_type)
                                         .where(referral_type_id: referral_type_id,
                                                organisation_id: current_user.organisation_id,
                                                is_active: true,
                                                is_deleted: false)
                                         .order(updated_at: :desc).limit(10)
  end

  def find_more_referrals
    limit_skip = params[:count].to_i * 10
    @sub_referral_types = SubReferralType.includes(:referral_type)
                                         .where(referral_type_id: params[:referral_type_id],
                                                organisation_id: current_user.organisation_id,
                                                is_active: true,
                                                is_deleted: false)
                                         .order(updated_at: :desc).skip(limit_skip).limit(10)
  end

  def respond_refresh
    respond_to do |format|
      format.js { render 'refresh.js.erb' }
    end
  end
end
