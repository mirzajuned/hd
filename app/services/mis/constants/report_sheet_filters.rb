# rubocop:disable all
class Mis::Constants::ReportSheetFilters
  def self.filters_array(mis_params)
    filter_map = {}
    filter_map['title'] = Mis::Constants::Badge.link_name( mis_params[:title])
    filter_map['start_date'] = mis_params[:start_date].strftime('%d/%m/%y')
    filter_map['end_date'] = mis_params[:end_date].strftime('%d/%m/%y')
    filter_map['facility_name'] = mis_params[:facility_name]
    filter_map['time_period'] = mis_params[:time_period]
    filter_map['current_state'] = mis_params[:current_state] if mis_params[:current_state].present?
    filter_map['appointmenttype'] = mis_params[:appointmenttype] if mis_params[:appointmenttype].present?
    filter_map['sub_appointment_type'] = mis_params[:appointment_type] if mis_params[:appointment_type].present?
    filter_map['consulting_doctor'] = User.find(mis_params[:consulting_doctor]).fullname if mis_params[:consulting_doctor].present?
    if mis_params[:initial_age].present? && mis_params[:final_age].present? && mis_params[:title] != 'user_wise_tat'&& mis_params[:title] != 'role_wise_tat' && mis_params[:title] != 'patient_time_spent_wise' 
      age =  mis_params[:final_age] == '0' ? 'All' : "#{mis_params[:initial_age]} : #{mis_params[:final_age]}"
      filter_map['age'] = age
    end
    filter_map['gender_type'] = mis_params[:gender_type] if mis_params[:gender_type].present?
    if mis_params[:referral_type_id].present?
      filter_map['referral_type'] = ReferralType.find(mis_params[:referral_type_id])&.name
    end
    filter_map['location_name'] = mis_params[:location_type] || 'city' if mis_params[:location_type].present?
    filter_map['role'] = mis_params[:role_name] || 'All' if mis_params[:role_name].present?
    filter_map['investigation_status'] = mis_params[:investigation_state] if mis_params[:investigation_state].present?
    filter_map['sort_by'] = (mis_params[:investigation_date_wise] + " Date") if mis_params[:investigation_date_wise].present?
    filter_map['investigation_type'] = mis_params[:investigation_type_name] if mis_params[:investigation_type_name].present?
    filter_map['performed_at'] = mis_params[:performed_at] if mis_params[:performed_at].present?
    filter_map['performed_by'] = mis_params[:performed_by_name] if mis_params[:performed_by_name].present?
    filter_map['advised_by'] = mis_params[:advised_by_name] if mis_params[:advised_by_name].present?
    [filter_map]
  end

  def self.inpatient_filters(mis_params)
    filter_map = {}
    filter_map['title'] = Mis::Constants::Badge.link_name( mis_params[:title])
    filter_map['start_date'] = mis_params[:start_date].strftime('%d/%m/%y')
    filter_map['end_date'] = mis_params[:end_date].strftime('%d/%m/%y')
    filter_map['facility_name'] = mis_params[:facility_name]
    filter_map['time_period'] = mis_params[:time_period]
    filter_map['ipd_current_status'] = mis_params[:ipd_current_status] if mis_params[:ipd_current_status].present?
    filter_map['admission_type'] = mis_params[:admission_type] if mis_params[:admission_type].present?
    filter_map['moh'] = mis_params[:moh] if mis_params[:moh].present?
    filter_map['consulting_doctor'] = mis_params[:consulting_doctor] if mis_params[:consulting_doctor].present?
    if mis_params[:initial_age].present? && mis_params[:final_age].present?
      age =  mis_params[:final_age] == '0' ? 'All' : "Between #{mis_params[:initial_age]} and #{mis_params[:final_age]}"
      filter_map['age'] = age
    end
    filter_map['gender_type'] = mis_params[:gender_type] if mis_params[:gender_type].present?

    filter_map['location_name'] = mis_params[:location_type] || 'city' if mis_params[:location_type].present?
    [filter_map]
  end

  def self.procedure_filters(mis_params)
    filter_map = {}
    filter_map['title'] = Mis::Constants::Badge.link_name( mis_params[:title])
    filter_map['start_date'] = mis_params[:start_date].strftime('%d/%m/%y')
    filter_map['end_date'] = mis_params[:end_date].strftime('%d/%m/%y')
    filter_map['facility_name'] = mis_params[:facility_name]
    filter_map['time_period'] = mis_params[:time_period]
    filter_map['procedure_state'] = mis_params[:procedure_state] if mis_params[:procedure_state].present?
    filter_map['procedure_name'] = mis_params[:procedure_name] if mis_params[:procedure_name].present?
    filter_map['advised_by'] = mis_params[:advised_by_name] if mis_params[:advised_by_name].present?
    filter_map['performed_by'] = mis_params[:performed_by_name] if mis_params[:performed_by_name].present?
    if mis_params[:doctor_type].present? && mis_params[:consulting_doctor].present?
      filter_map['doctor_type'] = mis_params[:doctor_type]
      filter_map['consulting_doctor'] = "#{mis_params[:doctor_type]}-by-#{mis_params[:consulting_doctor]}"
    end
    if mis_params[:initial_age].present? && mis_params[:final_age].present?
      age =  mis_params[:final_age] == '0' ? 'All' : "Between #{mis_params[:initial_age]} and #{mis_params[:final_age]}"
      filter_map['age'] = age
    end
    filter_map['gender_type'] = mis_params[:gender_type] if mis_params[:gender_type].present?

    filter_map['location_name'] = mis_params[:location_type] || 'city' if mis_params[:location_type].present?
    [filter_map]
  end

  def self.diagnosis_filters(mis_params)
    filter_map = {}
    filter_map['title'] = Mis::Constants::Badge.link_name( mis_params[:title])
    filter_map['start_date'] = mis_params[:start_date].strftime('%d/%m/%y')
    filter_map['end_date'] = mis_params[:end_date].strftime('%d/%m/%y')
    filter_map['facility_name'] = mis_params[:facility_name]
    filter_map['time_period'] = mis_params[:time_period]
    filter_map['procedure_state'] = mis_params[:procedure_state] if mis_params[:procedure_state].present?
    filter_map['procedure_name'] = mis_params[:procedure_name] if mis_params[:procedure_name].present?
    
    [filter_map]
  end

  def self.revenue_filters(mis_params)
    mis_filter_params = mis_params.stringify_keys
    mis_filter_params['start_date'] = mis_filter_params['start_date'].strftime('%d/%m/%y')
    mis_filter_params['end_date'] = mis_filter_params['end_date'].strftime('%d/%m/%y')
    mis_filter_params = mis_filter_params.select { |k, v| k.in?(mis_filters) && v.present? && v!='All' }
    [mis_filter_params.transform_keys(&:titleize).transform_values(&:titleize)]
  end

  def self.mis_filters
    ['time_period', 'start_date', 'end_date', 'facility_name', 'department_name', 'bill_type', 'doctor_name', 'pharmacy_store_name', 'optical_store_name', 'discount_type']
  end

  def self.referral_filters(mis_params)
    filter_map = {}
    filter_map['title'] = Mis::Constants::Badge.link_name(mis_params[:title])
    filter_map['start_date'] = mis_params[:start_date].strftime('%d/%m/%y')
    filter_map['end_date'] = mis_params[:end_date].strftime('%d/%m/%y')
    filter_map['facility_name'] = mis_params[:facility_name]
    filter_map['time_period'] = mis_params[:time_period]
    filter_map['referral_type'] = mis_params[:referral_type] if mis_params[:referral_type].present?
    filter_map['referred_date'] = mis_params[:referred_date] if mis_params[:referred_date].present?
    [filter_map]
  end
end
