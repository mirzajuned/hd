# rubocop:disable all
# 4   Metrics/MethodLength
# 3   Metrics/AbcSize
# 2   Metrics/CyclomaticComplexity
# 2   Metrics/LineLength
# 2   Metrics/PerceivedComplexity
# 1   Metrics/ClassLength
# --
# 14  Total
class Patients::CreateService
  class << self
    def call(params, current_user, current_facility = nil)
      # Create Additional Patient Params
      organisation_id = current_user.organisation_id.to_s
      facility = current_facility
      params[:patient][:reg_hosp_ids] = [organisation_id]
      params[:patient][:reg_status] = false unless params[:patient][:reg_status]
      # params[:patient][:reg_date] = Date.current
      # params[:patient][:reg_time] = Time.current

      if params[:patient][:fullname].present?
        params[:patient][:firstname] = params[:patient][:fullname]
      else
        params[:patient][:fullname] = "#{params[:patient][:salutation]} #{params[:patient][:firstname]} #{params[:patient][:middlename]} #{params[:patient][:lastname]}".split.join(' ')
      end
      params[:patient][:mobilenumber] = '0000000000' if params[:patient][:mobilenumber].blank?

      patient_age_create(params[:patient])
      params[:patient][:exact_age] = get_exact_age(params[:patient][:age].to_i, params[:patient][:age_month].to_i)
      # Update Patient DOB
      if params[:patient][:patientassets_attributes].present?
        if params[:patient][:patientassets_attributes]['0'][:asset_path_data_uri].present?
          params[:patient][:patientassets_attributes]['0'][:asset_path] = convert_data_uri_to_upload(params[:patient][:patientassets_attributes]['0'][:asset_path_data_uri])
        end
      end

      params[:patient][:whatsappnumber] = params[:patient][:mobilenumber] if params[:patient][:whatsappnumber].blank? && params[:patient][:same_as_mobilenumber] != "false"

      patient = Patient.create!(patient_params(params))
      return unless patient

      # Update Camp Patient
      update_camp_patient(patient) if params[:patient][:camp_patient_identifier]

      # Create FakePatientAsset
      create_patient_asset(patient) unless params[:patient][:patientassets_attributes].present?

      # Create PatientIdentifier
      create_patient_identifier(patient, current_user, facility) if params[:patient][:reg_status]

      # Create PatientOtherIdentifier
      if params[:patient_other_identifier].present?
        create_patient_other_identifier(params[:patient_other_identifier], patient, current_user)
      end

      if patient.dob_year.present?
        data_hash = {}
        data_hash['new_systemic_history'] = patient.try(:personal_histories)
        data_hash['new_eye_drop_allergy'] = patient.try(:eye_drops)
        data_hash['dob_year']             = patient.try(:dob_year)
        data_hash['organisation_id']      = patient.try(:reg_hosp_ids)[0]
        data_hash['gender']               = patient.try(:gender)
        Analytics::CreateService.call(data_hash, nil, nil, 'patients_history')
      end
      # Create PatientHistory
      if params[:patient_history].present?
        params[:patient_history][:patient_id] = patient.id.to_s
        PatientHistory.create!(patient_history_params(params))
      end

      # Create PatientSearch
      create_patient_search(patient) if params[:patient][:reg_status]

      # PatientJobs::PatientHistoryJob.perform_later(patient.id.to_s)

      if patient.patient_type_id.present?
        analytics_params = {}
        analytics_params['patient_id'] = patient.id
        analytics_params['organisation_id'] = organisation_id
        Analytics::CreateService.call(analytics_params.to_json, nil, nil, 'patient')
      end

      patient
    end

    private

    def get_exact_age(year, month)
      years = "#{year} Year".pluralize(year)
      months = "#{month} Month".pluralize(month)
      @exact_age = if year > 0 && month > 0
                     "#{years}-#{months}"
                   elsif year > 0
                     years
                   elsif month > 0
                     months
                   end
    end

    def update_camp_patient(patient)
      # camp_patient = CampPatient.find_by(camp_patient_identifier: patient.try(:camp_patient_identifier)) #PAT-CAMP6758 this way code doesn't break for past clinical reports and new ones are correct
      camp_patient = CampPatient.find_by(id: patient.try(:camp_patient_id)) #PAT-CAMP6758
      camp_patient.update(patient_id: patient.id, converted: true)
    end

    def create_patient_asset(patient)
      media = File.open(Rails.root + 'app/assets/images/placeholder.png')
      Patientasset.create!(patient_id: patient.id, asset_path: media)
    end

    def create_patient_identifier(patient, current_user, facility)
      patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
      patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: facility.id.to_s, region_id: facility.try(:region_master_id).to_s})
      patient_identifier.update(patient_org_id: patient_org_id)
    end

    def create_patient_other_identifier(params, patient, current_user)
      mr_no = params[:mr_no].to_s.strip.upcase
      organisation_id = current_user.organisation_id
      PatientOtherIdentifier.create!(patient_id: patient.id, mr_no: mr_no, organisation_id: organisation_id)
    end

    def create_patient_search(patient)
      patient_name = "#{patient.firstname} #{patient.middlename} #{patient.lastname}".strip
      patient_name_search = patient_name.tr('^A-Za-z0-9', '').downcase
      mobile_number = patient.mobilenumber
      mr_no = patient.patient_mrn
      mr_no_search = mr_no.to_s.tr('^A-Za-z0-9', '') # .split("").map {|x| x[/\d+/]}.join("")
      reg_hosp_ids = patient.reg_hosp_ids
      patient_identifier_id = patient.patient_identifier_id
      patient_identifier_id_search = patient_identifier_id.to_s.split('').map { |x| x[/\d+/] }.join('')

      search = "#{mobile_number} #{mr_no_search} #{patient_identifier_id_search} #{patient_name}"
      search += "#{mr_no_search} #{mobile_number} #{patient_name} #{patient_identifier_id_search}"
      search += "#{patient_identifier_id_search} #{patient_name} #{mobile_number} #{mr_no_search}"
      search += "#{patient_name} #{patient_identifier_id_search} #{mr_no_search} #{mobile_number}"

      PatientSearch.create(search: search.downcase, patient_id: patient.id, patient_name: patient_name,
                           mobile_number: mobile_number, mr_no: patient.patient_mrn,
                           patient_identifier_id: patient_identifier_id, reg_hosp_ids: reg_hosp_ids,
                           patient_identifier_id_search: patient_identifier_id_search,
                           mr_no_search: mr_no_search.downcase, patient_name_search: patient_name_search)
    end

    def patient_params(params)
      params.require(:patient).permit!.except(:id)
    end

    def patient_history_params(params)
      params.require(:patient_history).permit! # (:patient_id, :patientpersonalhistory, :patientallergyhistory)
    end

    def patient_registration_source_params(params)
      params.require(:patient_registration_source).permit(:source_type, :source_info, :source_date,
                                                          :source_doctor, :patient_id)
    end

    def referring_doctor_params(params)
      params.require(:referring_doctor).permit(:name, :mobile_number, :email, :hospital_name, :speciality, :city,
                                               :patient_id, :user_id)
    end

    def patient_age_create(params)
      if params[:dob].present?
        @dob = Date.parse(params[:dob])
        params[:age], params[:age_month] = set_age(@dob) if params[:age].blank?
        params[:dob_day] = @dob.day
        params[:dob_month] = @dob.month
        params[:dob_year] = @dob.year
        params[:is_approx_dob] = false
      elsif params[:age].present? && params[:age_month].present?
        params[:dob_day] = Date.current.day
        params[:dob_year] = Date.current.year - params[:age].to_i
        params[:dob_month] = Date.current.month - params[:age_month].to_i
        if params[:dob_month] < 0
          params[:dob_month] = params[:dob_month] + 12
          params[:dob_year] = params[:dob_year] - 1
        end
        params[:is_approx_dob] = true
      elsif params[:age].present? && params[:age_month].blank?
        params[:dob_day] = Date.current.day
        params[:dob_year] = Date.current.year - params[:age].to_i
        params[:dob_month] = Date.current.month
        params[:is_approx_dob] = true
      elsif params[:age].blank? && params[:age_month].present?
        params[:dob_day] = Date.current.day
        params[:dob_year] = Date.current.year
        params[:dob_month] = Date.current.month - params[:age_month].to_i
        if params[:dob_month] < 0
          params[:dob_month] = params[:dob_month] + 12
          params[:dob_year] = params[:dob_year] - 1
        end
        params[:is_approx_dob] = true
      end
    end

    # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
    def convert_data_uri_to_upload(obj_hash)
      if obj_hash.try(:match, /^data:(.*?);(.*?),(.*)$/)
        # image_data = split_base64(obj_hash)

        if obj_hash =~ /^data:(.*?);(.*?),(.*)$/
          uri = {}
          uri[:type] = Regexp.last_match(1) # "image/gif"
          uri[:encoder] = Regexp.last_match(2) # "base64"
          uri[:data] = Regexp.last_match(3) # data string
          uri[:extension] = Regexp.last_match(1).split('/')[1] # "gif"
          image_data =  uri
        else
          image_data =  nil
        end

        image_data_string = image_data[:data]
        image_data_binary = Base64.decode64(image_data_string)

        temp_img_file = Tempfile.new('data_uri-upload')
        temp_img_file.binmode
        temp_img_file << image_data_binary
        temp_img_file.rewind

        img_params = { filename: "data-uri-img.#{image_data[:extension]}",
                       type: image_data[:type], tempfile: temp_img_file }
        uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

        obj_hash = uploaded_file
      end

      obj_hash
    end

    def set_age(dob)
      now = Time.now.utc.to_date
      month_logic = (now.month > dob.month || (now.month == dob.month && now.day >= dob.day) ? 0 : 1)
      year = now.year - dob.year.to_i - month_logic
      month = now.month - dob.month.to_i
      day = now.day - dob.day.to_i
      month += 12 if month < 0
      month -= 1 if day < 0 && month != 0
      month = 11 if day < 0 && month == 0
      
      [year, month]
    end
  end
end
