# 4   Metrics/MethodLength
# 3   Metrics/AbcSize
# 2   Metrics/LineLength
# 1   Metrics/ClassLength
# 1   Metrics/CyclomaticComplexity
# 1   Metrics/PerceivedComplexity
# --
# 12  Total
class Patients::UpdateService
  class << self
    def call(patient_id, params, current_user)
      # Create Additional Patient Params
      if params[:patient][:fullname].present?
        params[:patient][:firstname] = params[:patient][:fullname]
      else
        params[:patient][:fullname] = "#{params[:patient][:salutation]} #{params[:patient][:firstname]} #{params[:patient][:middlename]} #{params[:patient][:lastname]}".strip
      end
      params[:patient][:exact_age] = get_exact_age(params[:patient][:age].to_i, params[:patient][:age_month].to_i)
      params[:patient][:referring_doctor_id] = nil

      patient = Patient.find_by(id: patient_id)
      params[:patient][:whatsappnumber] = params[:patient][:mobilenumber] if params[:patient][:whatsappnumber].blank? && params[:patient][:same_as_mobilenumber].present?

      # Create Patient DOB
      patient_age_update(params[:patient])

      past_patient_type_id = patient.patient_type_id
      past_organisation_id = patient.reg_hosp_ids[0]
      past_date = patient.reg_date
      if (patient.try(:reg_status) == false)
        params[:patient][:reg_status] = false unless params[:patient][:reg_status]
      end
      if params[:patient][:patientassets_attributes].present?
        params[:patient][:patientassets_attributes]['0'][:asset_path] = convert_data_uri_to_upload(params[:patient][:patientassets_attributes]['0'][:asset_path_data_uri]) if params[:patient][:patientassets_attributes]['0'][:asset_path_data_uri].present?
      end
      # for analytics patient history

      data_params = patient_params(params)
      data_hash = {}
      data_hash['old_systemic_history'] = patient.try(:personal_histories)
      data_hash['old_eye_drop_allergy'] = patient.try(:eye_drops)
      data_hash['new_systemic_history'] = data_params[:personal_histories]
      data_hash['new_eye_drop_allergy'] = data_params[:eye_drops]
      data_hash['old_dob_year']         = patient.try(:dob_year)
      data_hash['new_dob_year']         = data_params[:dob_year]
      data_hash['organisation_id']      = patient.try(:reg_hosp_ids)[0]
      data_hash['old_gender']           = patient.try(:gender)
      data_hash['new_gender']           = data_params[:gender]
      Analytics::UpdateService.call(data_hash, nil, nil, 'patients_history')

      patient_prev_reg_status = patient.try(:reg_status)

      begin
        patient.update_attributes!(patient_params(params))
      rescue NoMethodError
        # This is for assign_attributes issue
        raise unless Rails.env.production?
      end

      if (patient.try(:reg_status) == true && patient_prev_reg_status == false)
        facility = Facility.find_by(id: params[:patient][:reg_facility_id].to_s)
        # Create PatientIdentifier
        create_patient_identifier(patient, current_user, facility)
      end
      # patient.update_attributes(patient_asset_params(params))
      # Create PatientOtherIdentifier
      if params[:patient_other_identifier].present?
        create_patient_other_identifier(params[:patient_other_identifier], patient, current_user)
      end

      # Create PatientHistory
      # if params[:patient_history].present?
      #   params[:patient_history][:patient_id] = patient.id.to_s
      #   PatientHistory.find_by(patient_id: patient.id).update!(patient_history_params(params))
      # end

      # Create PatientSearch
      create_patient_search(patient)

      # Update Patient Details in Different Models
      update_patient_details(patient)
      patient.patientassets.where(asset_path: nil).delete_all
      # PatientJobs::PatientHistoryJob.perform_later(patient.id.to_s)

      if past_patient_type_id != patient.patient_type_id
        analytics_params = {}
        analytics_params['patient_id'] = patient.id
        analytics_params['organisation_id'] = past_organisation_id
        analytics_params['past_patient_type_id'] = past_patient_type_id
        analytics_params['past_date'] = past_date
        Analytics::UpdateService.call(analytics_params.to_json, nil, nil, 'patient')
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

    def create_patient_identifier(patient, current_user, facility)
      patient_identifier = PatientIdentifier.create!(patient_id: patient.id, organisation_id: current_user.organisation_id, bkp_patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
      patient_org_id = SequenceManagers::GenerateSequenceService.call('patient', patient.id.to_s, {organisation_id: current_user.organisation_id.to_s, facility_id: facility.id.to_s, region_id: facility.try(:region_master_id).to_s})
      patient_identifier.update(patient_org_id: patient_org_id)
    end

    def create_patient_other_identifier(params, patient, current_user)
      mr_no = params[:mr_no].to_s.strip.upcase
      @patient_other_identifier = PatientOtherIdentifier.find_by(patient_id: patient.id)
      if @patient_other_identifier.present?
        @patient_other_identifier.update(mr_no: mr_no)
      else
        organisation_id = current_user.organisation_id
        PatientOtherIdentifier.create!(patient_id: patient.id, mr_no: mr_no, organisation_id: organisation_id)
      end
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

      patient_search = PatientSearch.find_by(patient_id: patient.id)
      patient_search&.update(search: search.downcase, patient_id: patient.id, patient_name: patient_name,
                             mobile_number: mobile_number, mr_no: patient.patient_mrn,
                             patient_identifier_id: patient_identifier_id, reg_hosp_ids: reg_hosp_ids,
                             patient_identifier_id_search: patient_identifier_id_search,
                             mr_no_search: mr_no_search.downcase, patient_name_search: patient_name_search)
    end

    def update_patient_details(patient)
      # Investigation::Queue
      investigation_queue = Investigation::Queue.where(patient_id: patient.id)
      investigation_queue.try(:each) do |inv|
        inv.update(patient_name: patient.fullname)
      end
    end

    def patient_params(params)
      params.require(:patient).permit(:fullname, :salutation, :firstname, :middlename, :lastname, :mobilenumber,
                                      :secondarymobilenumber, :same_as_mobilenumber, :whatsapp_country_code, 
                                      :whatsapp_flag_code,:mobilenumber_country_code, :mobilenumber_flag_code, 
                                      :whatsappnumber,  :email, :gender, :dob, :age, :age_month, :exact_age,
                                      :dob_day, :dob_month, :dob_year, :is_approx_dob, :primary_language,
                                      :secondary_language, :address_1, :address_2, :district, :commune, :city, :state,
                                      :pincode, :aadhar_card_number, :pan_number, :driving_license_number,
                                      :health_id_number, :gst_number,
                                      :reg_date, :reg_time, :reg_status, :reg_facility_id,
                                      :social_security_number, :blood_group, :occupation, 
                                      :employee_id, :maritalstatus, :specialstatus, 
                                      :emergencycontactname, :emergencymobilenumber,
                                      :emergency_relation, :patient_type_id, :patient_type_info, 
                                      :one_eyed, :speciality_histories, :other_history, 
                                      :others_allergies, :personal_histories, :drug_allergies, 
                                      :drug_allergies_comment, :antimicrobial_agents, 
                                      :antifungal_agents, :antiviral_agents, :nsaids, :eye_drops,
                                      :contact_allergies,  :contact_allergies_comment, 
                                      :relative_name, :relative_relation,
                                      :food_allergies, :food_allergies_comment, 
                                      :referring_doctor_id, :patient_type_comment,
                                      :opthal_history_comment, :history_comment, 
                                      :no_opthalmic_history_advised,
                                      :no_systemic_history_advised, :no_allergy_advised,
                                      :diff_wearing_glasses, :diff_hearing_aid, 
                                      :diff_walking_climbing, :diff_remembring_concentrating, 
                                      :diff_selfcare, :diff_communicate, :nutritional_assessment, 
                                      :nutritional_assessment_comment, :immunization_assessment, 
                                      :immunization_assessment_comment, :area_manager_id,
                                      :area_manager_name, :location_id,
                                      speciality_history_records_attributes: {}, 
                                      allergy_histories_attributes: {},
                                      personal_history_records_attributes: {}, 
                                      other_history_attributes: {},
                                      reg_hosp_ids: [], patientassets_attributes: {})
    end

    def patient_history_params(params)
      params.require(:patient_history).permit!
    end

    def patient_registration_source_params(params)
      params.require(:patient_registration_source).permit(:source_type, :source_info, :source_date,
                                                          :source_doctor, :patient_id)
    end

    def referring_doctor_params(params)
      params.require(:referring_doctor).permit(:name, :mobile_number, :email, :hospital_name, :speciality, :city, :patient_id, :user_id)
    end

    def patient_age_update(params)
      if params[:dob].present?
        @dob = Date.parse(params[:dob])
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
      elsif params[:age].blank? && params[:age_month].blank? && params[:dob].blank?
        params[:dob_day] = nil
        params[:dob_year] = nil
        params[:dob_month] = nil
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
  end
end
