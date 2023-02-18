class OpdReferralsController < ApplicationController
  before_action :authorize
  before_action :opd_referrals_active, only: [:doctor_view, :search_referral]

  def doctor_view
    @viwed_opd_referral = if params[:type] == 'mark_as_viewed'
                            OpdReferral.find_by(id: params[:referral_id]).update(is_seen: true)
                          elsif params[:type] == 'delete'
                            OpdReferral.find_by(id: params[:referral_id]).update(is_deleted: true)
                          elsif params[:type] == 'delete_all'
                            OpdReferral.where(to_doctor: current_user.id).update_all(is_deleted: true)
                          end
    opd_referrals_active

    @opd_referral_count = @opd_referral.where(is_seen: false).count
  end

  def reception_view
    @opd_referral = OpdReferral.where(to_facility: current_facility_id,
                                      is_deleted: false,
                                      'referral_date' => { '$gte' => Date.current - 5 })
                               .order_by('referral_date asc')

    @opd_referral_count = @opd_referral.where(is_seen: false).count
  end

  def new_appointment
    @opd_referral_id = params[:opd_referral_id]
    @referred_to_doctor = OpdReferral.find_by(id: @opd_referral_id).to_doctor.to_s
    @appointment_types = AppointmentType.where(user_id: @referred_to_doctor, is_active: true)
    @patient = Patient.find(params[:patientid])
  end

  def specialty_data
    doctors = User.where(organisation_id: current_user.organisation_id,
                         facility_ids: current_facility.id,
                         role_ids: 158965000,
                         specialty_ids: params[:specialty_id],
                         is_active: true)
    appointment_types = AppointmentType.where(facility_id: current_facility.id,
                                              specialty_ids: params[:specialty_id],
                                              is_active: true)
    sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: current_user.organisation_id,
                                                                      specialty_ids: params[:specialty_id],
                                                                      is_active: true)
                                                               .order(created_at: :desc)

    render json: {
      doctors: doctors.pluck(:fullname, :id),
      appointment_types: appointment_types.pluck(:label, :id),
      sub_appointment_types: sub_appointment_types.pluck(:label, :id)
    }
  end

  def add_intra_facility_referral
    @current_facility = current_facility
    @current_user = current_user
    @counter = params[:ajax][:counter]
    specialty_id = params[:ajax][:specialty_id]
    @referral_specialties = Specialty.where(:id.in => @current_facility.specialty_ids)
    @intra_referral_doctors = User.where(organisation_id: @current_user.organisation_id,
                                         facility_ids: @current_facility.id,
                                         role_ids: 158965000,
                                         specialty_ids: specialty_id,
                                         is_active: true)
    @appointment_types = AppointmentType.where(facility_id: @current_facility.id,
                                               specialty_ids: specialty_id,
                                               is_active: true)
    @sub_appointment_types = OrganisationAppointmentCategoryType.where(organisation_id: @current_user.organisation_id,
                                                                       specialty_ids: specialty_id,
                                                                       is_active: true)
                                                                .order(created_at: :desc)
  end

  def add_inter_facility_referral
    @current_facility = current_facility
    @current_user = current_user
    @counter = params[:ajax][:counter]
    @specialty_id = params[:ajax][:specialty_id]
  end

  def add_outside_organisation_referral
    @counter = params[:ajax][:counter]
  end

  def search_referral
    respond_to do |format|
      format.js { render 'opd_referrals/search', layout: false }
    end
  end

  def search_referral_doctor
    facility_id = current_facility.id.to_s
    sub_referral_types = SubReferralType.where(referral_type_id: 'FS-RT-0002',
                                               is_deleted: false,
                                               facility_ids: facility_id,
                                               name: /#{Regexp.escape(params[:q])}/i)
    doc_names = sub_referral_types.pluck(:name)
    render json: doc_names
  end

  private

  def opd_referrals_active
    if params[:search].present? && params[:search].length > 2
      r_query = params[:search].split(' ').join('.*')
      @opd_referral = OpdReferral.where(to_doctor: current_user.id, patient_name: /#{r_query}/i)
                                 .limit(5)
    else
      @opd_referral = OpdReferral.where(to_doctor: current_user.id,
                                        is_deleted: false,
                                        'referral_date' => { '$gte' => Date.current - 5 })
                                 .order_by('referral_date asc')

    end
  end
end
