module CommonHelper

  def self.get_number_format(current_facility, current_organisation)
    number_format = current_facility['number_format'] || current_organisation['number_format'] || 0
  end

  def self.get_custom_ophthal_investigation_identifier(current_user)
    sequence_id = current_user.organisation.ophthal_investigations_counter
    current_user.organisation.inc(ophthal_investigations_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}oph#{sequence_id}"
  end

  def self.get_custom_radiology_investigation_identifier(current_user)
    sequence_id = current_user.organisation.radiology_investigations_counter
    current_user.organisation.inc(radiology_investigations_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}rad#{sequence_id}"
  end

  def self.get_custom_laboratory_investigation_identifier(current_user)
    sequence_id = current_user.organisation.laboratory_investigations_counter
    current_user.organisation.inc(laboratory_investigations_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}lab#{sequence_id}"
  end

  def self.get_custom_laboratory_id_investigation_identifier(current_user)
    sequence_id = current_user.organisation.laboratory_investigations_id_counter
    current_user.organisation.inc(laboratory_investigations_id_counter: 1)
    sequence_id.to_s
  end

  def self.get_common_procedure_identifier(current_user)
    sequence_id = current_user.organisation.procedures_counter
    current_user.organisation.inc(procedures_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}pcs#{sequence_id}"
  end

  def self.get_translated_procedure_identifier(current_user)
    sequence_id = current_user.organisation.procedures_counter
    current_user.organisation.inc(procedures_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}tcs#{sequence_id}"
  end

  def self.get_common_icd_identifier(current_user)
    sequence_id = current_user.organisation.diagnosis_counter
    current_user.organisation.inc(diagnosis_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}icd#{sequence_id}"
  end

  def self.get_translated_icd_identifier(current_user)
    sequence_id = current_user.organisation.diagnosis_counter
    current_user.organisation.inc(diagnosis_counter: 1)
    identifier_prefix = current_user.organisation.identifier_prefix.downcase
    "#{identifier_prefix}tcd#{sequence_id}"
  end

  def self.get_invoice_record_identifier(current_user)
    sequence_id = current_user.organisation.invoice_counter
    current_user.organisation.inc(invoice_counter: 1)
    "#{current_user.organisation.identifier_prefix}-INV-#{sequence_id}"
  end

  def self.get_advance_identifier(current_user)
    sequence_id = current_user.organisation.advance_counter
    current_user.organisation.inc(advance_counter: 1)
    "#{current_user.organisation.identifier_prefix}-ADV-#{sequence_id}"
  end

  def self.get_refund_identifier(current_user)
    sequence_id = current_user.organisation.refund_counter
    current_user.organisation.inc(refund_counter: 1)
    "#{current_user.organisation.identifier_prefix}-RFD-#{sequence_id}"
  end

  def self.get_cash_register_record_identifier(current_user)
    sequence_id = current_user.organisation.cash_register_counter
    current_user.organisation.inc(cash_register_counter: 1)
    "#{current_user.organisation.identifier_prefix}-CSH-#{sequence_id}"
  end

  def self.get_opd_record_identifier(current_user)
    sequence_id = current_user.organisation.opd_counter
    current_user.organisation.inc(opd_counter: 1)
    "#{current_user.organisation.identifier_prefix}-OPD-#{sequence_id}"
  end

  def self.get_patient_org_identifier(current_user)
    sequence_id = current_user.organisation.patient_counter
    current_user.organisation.inc(patient_counter: 1)
    "#{current_user.organisation.identifier_prefix}-PAT-#{sequence_id}"
  end

  def self.get_org_identifier_patient(organisation)
    sequence_id = organisation.patient_counter
    organisation.inc(patient_counter: 1)
    "#{organisation.identifier_prefix}-PAT-#{sequence_id}"
  end

  def self.get_ipd_record_identifier(current_user)
    sequence_id = current_user.organisation.ipd_counter
    current_user.organisation.inc(ipd_counter: 1)
    "#{current_user.organisation.identifier_prefix}-IPD-#{sequence_id}"
  end

  def self.gen_org_account_identifier(identifier_prefix, current_user)
    sequence_id = current_user.organisation.account_counter
    current_user.organisation.inc(account_counter: 1)
    "#{identifier_prefix}-ACC-#{sequence_id}"
  end

  def self.gen_investigation_identifier(current_user)
    sequence_id = current_user.organisation.invoice_counter
    current_user.organisation.inc(invoice_counter: 1)
    "#{current_user.organisation.identifier_prefix}-OPT-#{sequence_id}"
  end

  def self.get_case_id(organisation)
    sequence_id = organisation.try(:case_counter)
    organisation.inc(case_counter: 1)
    "#{organisation.try(:identifier_prefix)}-CS-#{sequence_id}"
  end

  # def self.get_er_record_number()
  # "#{Date.current.beginning_of_year.financial_year.to_s}-#{Date.current.financial_year.to_s[2,3]}/XYZ-BLR/ER/#{sequence_id}"
  # end

  def self.get_service_master_code(current_user)
    organisation = current_user.organisation
    sequence_id = organisation.service_master_counter.to_i
    organisation.inc(service_master_counter: 1)
    "#{organisation.identifier_prefix}-SRM-#{sequence_id}"
  end

  def self.get_pricing_master_code(facility)
    sequence_id = facility.pricing_master_counter.to_i
    facility.inc(pricing_master_counter: 1)
    "#{facility.abbreviation}-PRM-#{sequence_id}"
  end

  def get_schedule_time_for_current_user
    @day_today = Time.current.strftime('%A').downcase
    @timing_array = []
    @split_schedule = {}
    current_user.facilities.each do |facility|
      @split_schedule = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id, facility_id: facility.id)
      @split_schedule = @split_schedule.schedule if @split_schedule.present?
    end
    return @current_facility_id = current_user.facilities[0].id if @split_schedule.nil?

    @split_schedule = @split_schedule[:"#{@day_today}"]
    @split = @split_schedule.split('%%%')
    @split.each do |s|
      s = s.split('$$$')
      @timing_array.push(s)
    end
    compare_schedule_with_current_time @timing_array
  end

  def compare_schedule_with_current_time(timing_array)
    @interval = []
    @time_now = Time.current
    timing_array.each do |time_interval|
      @interval = time_interval[0].split('&&&')
      if @time_now.between?(Time.zone.parse(@interval[0]), Time.zone.parse(@interval[1]))
        @current_facility_id = time_interval[1]

      end
    end
    @current_facility_id = current_user.facilities[0].id if @current_facility_id.nil?
  end

  def add_facility_timings(user)
    @user = User.find_by(id: user.id)
    @facility_timing = []
    @user.facilities.each do |facility|
      if @user.roles[0].name == 'doctor' || @user.roles[1].try(:name) == 'doctor'
        @facility_timing.push(Hash[facility.id.to_s => UsersSetting.doctor_setting])
      else
        @facility_timing.push(Hash[facility.id.to_s => UsersSetting.nurse_setting])
      end
    end
    @user.users_setting.update_attributes(facility_timing: @facility_timing)
  end

  def add_delete_facility_timings(user)
    @user = User.find_by(id: user.id)
    # add id
    check_id = ''
    @facility_timing = []
    @user.users_setting.facility_timing.try(:each) do |facility_hash|
      facility_hash.each do |facility_id, timing_hash|
        @facility_timing.push(Hash[facility_id => timing_hash])
        check_id = check_id + '#####' + facility_id.to_s
      end
    end
    @user.facilities.each do |facility|
      unless check_id.include? facility.id.to_s
        if @user.roles[0].name == 'doctor' || @user.roles[1].try(:name) == 'doctor'
          @facility_timing.push(Hash[facility.id.to_s => UsersSetting.doctor_setting])
        else
          @facility_timing.push(Hash[facility.id.to_s => UsersSetting.nurse_setting])
        end
      end
    end
    @user.users_setting.update_attributes(facility_timing: @facility_timing)
    # delte id
    check_id = ''
    @user.facilities.each do |facility|
      check_id = check_id + '#####' + facility.id.to_s
    end
    @user.users_setting.facility_timing.each do |facility_hash|
      facility_hash.each do |facility_id, _timing_hash|
        i = 0
        @facility_timing.delete_at(i) unless check_id.include? facility_id.to_s
      end
    end
    @user.users_setting.update_attributes(facility_timing: @facility_timing)
  end

  def self.sankara_dmr_integration(mr_no)
    mr_no.length > 2 ? mr_no.gsub("/", "") : "NOMRN"
  end

  def self.get_counselling_record_identifier
    id = Order::CounsellingRecord.count + 1
    seq = sprintf '%04d', id
    "COUNR#{seq}"
  end

  def self.get_order_identifier
    id = Order::Advised.count + 1
    seq = sprintf '%04d', id
    "ORDR#{seq}"
  end

  def self.get_procedure_order_identifier(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    sequence_id = organisation.procedures_order_counter
    organisation.inc(procedures_order_counter: 1)
    "PCS-ORDR-#{sequence_id}"
  end

  def self.get_investigation_order_identifier(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)
    sequence_id = organisation.investigations_order_counter
    organisation.inc(investigations_order_counter: 1)
    "INV-ORDR-#{sequence_id}"
  end

  def self.get_time_of_day(hour)
    if (hour >= 0 and hour <= 5)
      return "mid_night"
    elsif (hour > 5 and hour <= 9)
      return "early_morning"
    elsif (hour > 9 and hour <= 11)
      return "late_morning"
    elsif (hour > 11 and hour <= 13)
      return "early_afternoon"
    elsif (hour > 13 and hour <= 16)
      return "late_afternoon"
    elsif (hour > 16 and hour <= 19)
      return "evening"
    elsif (hour > 19 and hour <= 23)
        return "night"
    end
  end
end
