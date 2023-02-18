module OpdRecordsHelper
  def self.translate_medication_status(status, language)
    medicine_status = {
      'C' => 'continue',
      'D' => 'discontinue',
      'N' => 'new'
    }
    if status
      LanguageHelper.translation(medicine_status[status], language)
    else
      LanguageHelper.translation('new', language)
    end
  end

  def self.medicine_frequency(frequency)
    if frequency == 'SOS'
      frequency
    else
      "#{frequency} times a day"
    end
  end

  def self.medicine_duration(duration_option, duration)
    if duration_option == 'F'
      'Next Followup'
    elsif duration_option == 'W'
      duration.to_s + ' ' + 'Week'.pluralize(duration)
    elsif duration_option == 'M'
      duration.to_s + ' ' + 'Month'.pluralize(duration)
    elsif duration_option == 'D'
      duration.to_s + ' ' + 'Day'.pluralize(duration)
    end
  end

  def self.medicine_eyeside(eyeside)
    if eyeside.present?
      if eyeside == 'L'
        'Left'
      elsif eyeside == 'R'
        'Right'
      elsif eyeside == 'BE'
        'Both Eyes'
      end
    else
      '-'
    end
  end

  def self.enabled_templates(organisation_setting, patient_id, appointment_date, specialty_id)
    discharged_admission = Admission.where(
      patient_id: patient_id, :dischargedate.lte => Date.current, isdischarged: true
    ).sort(dischargedate: :desc).first

    return unless discharged_admission && appointment_date > discharged_admission.dischargedate

    specialty = Specialty.find_by(id: specialty_id)

    discharge_duration = TimeDifference.between(Date.current, discharged_admission.dischargedate).in_days.to_i
    return unless discharge_duration < organisation_setting.disable_opd_templates_duration.to_i

    organisation_setting.allowed_opd_templates[specialty.name.downcase]
  end

  def self.medical_instructions(medication, medication_set_arr, country_id, lang = nil)
    if medication['medicineinstructions'].present?
      medication['medicineinstructions']
    elsif medication['instruction'].present?
      set = medication_set_arr.select { |medi| medi['id'] == medication['instruction'] }
      if set[0].present?
        if lang.present?
          set[0][lang]
        elsif country_id == 'VN_254'
          set[0]['vi']
        else
          set[0]['en']
        end
      end
    end
  end

  def default_medication_set(language)
    default_set = []
    ['not_applicable', 'continue', 'discontinue'].each do |s|
      default_set << LanguageHelper.translation(s, language)
    end
    default_set
  end

  def self.phr_medication_table(medication, translated_language, current_facility)
    med_array = {}
    med_name = medication.medicinename.to_s.upcase
    med_name += " - #{medication.medicinetype.to_s.upcase}" if medication.medicinetype?
    med_frequency = ''
    med_duration = ''
    med_side = ''
    medication_set_arr = Global.send('medication_instruction_option').send('sets')
    if medication.taper_id == '0' || medication.taper_id.nil? || medication.taper_id == ''
      if medication.medicinefrequency.present?
        med_frequency = OpdRecordsHelper.medicine_frequency(medication.medicinefrequency)
      end
      if medication.medicinedurationoption && medication.medicineduration
        med_duration = OpdRecordsHelper.medicine_duration(medication.medicinedurationoption, medication.medicineduration)
      end
      med_side = OpdRecordsHelper.medicine_eyeside(medication['eyeside']) if medication['eyeside'].present?
      med_array = {
        'name': med_name,
        'qty': medication.medicinequantity,
        'frequency': med_frequency,
        'instruction': medication.medicineinstructions,
        'side': med_side,
        'comments': OpdRecordsHelper.medical_instructions(medication, medication_set_arr, current_facility.country_id),
        'duration': med_duration,
        'tapering': false
      } # .select! { |_k, v| v.present? }
    else
      med_side = OpdRecordsHelper.medicine_eyeside(medication['eyeside']) if medication['eyeside'].present?
      med_array = {
        'name': med_name,
        'instruction': medication.medicineinstructions,
        'qty': medication.medicinequantity,
        'side': med_side,
        'tapering': true,
        'values': phr_medication_tapering_json(medication, translated_language)
      } # .select!() {|k, v| v.present? }
    end
    med_array
    # rescue => e
    #   Rails.logger.error("Error in phr_medication_table:: #{e.inspect}")
    #   puts e.inspect
  end

  def get_provisional_diagnosis_history(case_sheet_id)
    @provisional_diagnosis_history = {}
    begin
      case_sheet = CaseSheet.find_by(id: case_sheet_id.to_s)
      history_provisional_diagnosis(case_sheet)
    rescue StandardError => e
      @provisional_diagnosis_history[:message] = e.inspect
      @provisional_diagnosis_history[:count] = 0
    end
    @provisional_diagnosis_history
  end

  def get_last_provisional_diagnosis(opdrecord)
    @provisional_diagnosis_history = {}
    begin
      last_provisional_diagnosis(opdrecord)
    rescue StandardError => e
      @provisional_diagnosis_history[:message] = e.inspect
      @provisional_diagnosis_history[:count] = 0
    end
    @provisional_diagnosis_history
  end

  def self.visualacuity_unaided(side_visualacuity_unaided)
    side_visualacuity_unaided.gsub('-', ' Absent').gsub('+', ' Present')
  end

  def self.show_squint(opdrecord)
    ['r','l','m','near','pd','sd'].each do |side|
      (1..14).each do |num|
        return true if opdrecord.send("#{side}_squint_select_#{num}").present?
        return true if opdrecord.send("#{side}_squint_input_#{num}").present?
      end
    end
    return false
  end

  private

  def history_provisional_diagnosis(case_sheet)
    if case_sheet[:provisional_diagnosis] && case_sheet[:provisional_diagnosis].count > 0
      case_sheet[:provisional_diagnosis].values.reverse_each do |provisional_d|
        if provisional_d['content'].present?
          @provisional_diagnosis_history[provisional_d['date'].localtime] = "#{provisional_d['content']} <strong>by </strong> #{provisional_d['consultant_name']}"
        end
      end

      if @provisional_diagnosis_history.count == 0
        @provisional_diagnosis_history[:message] = 'Provisional Diagnosis Not Found'
        @provisional_diagnosis_history[:count] = 0
      end
    else
      @provisional_diagnosis_history[:message] = 'Provisional Diagnosis Not Found'
      @provisional_diagnosis_history[:count] = 0
    end
    @provisional_diagnosis_history
  end

  def last_provisional_diagnosis(opdrecord)
    if opdrecord.provisional_diagnosis.empty?
      @provisional_diagnosis_history[:message] = 'Provisional Diagnosis Not Found'
      @provisional_diagnosis_history[:count] = 0
    else
      @provisional_diagnosis_history[opdrecord.updated_at] = "#{opdrecord.provisional_diagnosis} <strong>by </strong> #{User.find(opdrecord.consultant_id.to_s).try(:fullname)}"
    end
    @provisional_diagnosis_history
  end

  def self.phr_medication_tapering_json(medication, _translated_language)
    tapering_ary = []
    tapering_json = {}
    taper = TaperingKit.find_by(id: medication.try(:taper_id))
    tapering_set = taper.tapering_set
    taper_by = taper.taper_by
    if taper.taperingtype == 'W'
      w_tapering_ary = []
      tapering_set.each do |taper|
        frequency = taper.frequency.to_i
        next if frequency == 0

        interval = taper.interval.to_i
        t_interval = interval > 0 ? "Every #{interval} #{'hour'.pluralize(interval)}" : '-'
        t_frequency = begin
          "#{frequency} #{'time'.pluralize(frequency)} a day"
                      rescue StandardError
                        ''
        end
        if taper.dosage.present?
          taperkey = 'frequency'
          tapervalue = taper.dosage
        else
          taperkey = 'frequency'
          tapervalue = t_frequency
        end
        taper_h = {
          'taper_by': taper_by,
          'duration': "#{taper.start_date.to_s(:hg_taper_date_format)} to #{taper.end_date.to_s(:hg_taper_date_format)}",
          'interval': t_interval,
          "no_of_days": taper.number_of_days,
          'timings': "Between #{taper.start_time.to_s(:hg_taper_time_format)} and #{taper.end_time.to_s(:hg_taper_time_format)}"
        } # .select!() {|k, v| v.present? }
        taper_h[taperkey] = tapervalue

        w_tapering_ary << taper_h
      end
      tapering_json = {
        'title': 'As Advised below',
        'taper_by': taper.taper_by,
        'tapering_values': w_tapering_ary
      }
    else
      d_tapering_ary = []
      tapering_set.each do |taper|
        frequency = taper.frequency.to_i
        next if frequency == 0

        interval = taper.interval.to_i
        t_interval = interval > 0 ? "Every #{interval} #{'hour'.pluralize(interval)}" : '-'
        t_frequency = begin
          "#{frequency} #{'time'.pluralize(frequency)} a day"
                      rescue StandardError
                        ''
        end
        if taper.dosage.present?
          taperkey = 'frequency'
          tapervalue = taper.dosage
        else
          taperkey = 'frequency'
          tapervalue = t_frequency
        end
        taper_h = {
          'taper_by': taper_by,
          'duration': taper.start_date.to_s(:hg_taper_date_format),
          'interval': t_interval,
          "no_of_days": taper.number_of_days,
          'timings': "Between #{taper.start_time.to_s(:hg_taper_time_format)} and #{taper.end_time.to_s(:hg_taper_time_format)}"
        } # .select!() {|k, v| v.present? }
        taper_h[taperkey] = tapervalue

        d_tapering_ary << taper_h
      end
      tapering_json = {
        'title': 'As Advised below',
        'taper_by': taper.taper_by,
        'tapering_values': d_tapering_ary
      }
    end
    tapering_ary << tapering_json
    tapering_ary
  end

  def self.get_label_for_opd_followup_timeframe(followuptimeframeids)
    opdfollowuptimeframetext = ''
    opdfollowuptimeframearray = []

    followuptimeframeids.split(',').each do |followuptimeframeid|
      opdfollowuptimeframesingletext = ''
      Global.ehrcommon.opdfollowuptimeframe.each do |opdfollowuptimeframe|
        next unless opdfollowuptimeframe['id'].to_i == followuptimeframeid.to_i

        opdfollowuptimeframesingletext = opdfollowuptimeframe['snomedname']
        if followuptimeframeid.to_i == 88694003
          opdfollowuptimeframearray.unshift(opdfollowuptimeframesingletext)
        elsif followuptimeframeid.to_i == 310341009
        else
          opdfollowuptimeframearray << opdfollowuptimeframesingletext
        end
      end
    end

    if followuptimeframeids.split(',').include?('310341009')
      if followuptimeframeids.split(',').size == 1
        opdfollowuptimeframearray.append('for review as and when necessary')
      else
        opdfollowuptimeframearray.append('as and when necessary')
      end
    end

    unless opdfollowuptimeframearray[0] == 'Immediately' || opdfollowuptimeframearray[0] == 'for review as and when necessary'
      opdfollowuptimeframearray.insert(0, 'after')
    end

    opdfollowuptimeframetext = opdfollowuptimeframearray[0] == 'after' ? opdfollowuptimeframearray.join(' or ').sub('or', '') : opdfollowuptimeframearray.join(' or ')

    opdfollowuptimeframetext
  end

  def optical_store_dropdown(opdrecord, stores_array)
    value = if opdrecord.optical_store_id || !opdrecord.new_record?
              opdrecord.optical_store_id.to_s
            else
              stores_array[0][1].to_s
    end
    select_tag 'opdrecord[view_optical_store_id]',
               options_for_select(stores_array, value),
               { class: 'form-control', style: 'width: 100%;padding: 8px 0px;' }
  end
end
