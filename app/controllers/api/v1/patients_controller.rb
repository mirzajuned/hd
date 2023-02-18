module Api
  module V1
    class PatientsController < ApiApplicationController
      before_action :authorize_token
      # before_action :restrict_access

      api :POST, '/api/v1/patients/register', 'Register patient on mobile and tablet'
      formats ['json']
      description <<-EOS
          == Register patient on mobile and tablet
             URL: /api/v1/patients/register
             This is example json,
             JSON format to register patient. Ex json: {"fullname": "Max Maniar", "gender": "Male or Female", "age": 21, "dob": "yyyy-mm-dd", "mobilenumber": "9900000000", "email": "johndoe@myemail.com",patientassets_attributes: {0:{:asset_path=>'picture'}} }
              response if created => {created:true,id:'id',display_id:'disp id'}
              response if failed=> {created:false}
      EOS

      def search_patient
        r_query = params[:search].split(' ').join('.*')
        @user = User.find_by(id: params[:current_user_id])
        @patient_list = PatientSearch.where(reg_hosp_ids: @user.organisation_id.to_s, search: /#{r_query}/i).limit(8)
        # render :json =>  @patientlist.to_json
        respond_to do |format|
          format.json {}
        end
      end

      def search_patient_mr_no
        r_query = params[:search].delete(' ')
        @patient_list = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mr_no_search: /^#{r_query}/).limit(8)
        respond_to do |format|
          format.json {}
        end
      end

      def search_patient_mobile_no
        r_query = params[:search].delete(' ')
        @patient_list = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, mobile_number: r_query.to_i).limit(8)
        respond_to do |format|
          format.json {}
        end
      end

      def search_patient_name
        r_query = params[:search].delete(' ')
        @patient_list = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_name_search: /^#{r_query}/).limit(8)
        respond_to do |format|
          format.json {}
        end
      end

      def search_patient_identifier
        r_query = params[:search].delete(' ')
        @patient_list = PatientSearch.where(reg_hosp_ids: current_user.organisation_id.to_s, patient_identifier_id_search: /^#{r_query}/).limit(8)
        respond_to do |format|
          format.json {}
        end
      end

      def register
        params[:reg_date] = Date.current
        @organisation = Organisation.find_by(id: params['organisation_id'].to_s)
        params[:reg_hosp_ids] = [@organisation.id.to_s]
        @patient = Patient.new(patient_create_params)
        if @patient.save
          @patient_identifier = PatientIdentifier.create(patient_id: @patient.id, organisation_id: @organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
          @status_flag = true
        else
          @status_flag = false
        end
        respond_to do |format|
          format.json { render 'register_new_patient', layout: false }
        end
      end

      api :POST, '/api/v1/patients/selfregister', 'Self patient registration tool over tablet'
      formats ['json']
      description <<-EOS
          == Self patient registration tool over tablet
             URL: /api/v1/patients/selfregister
             This is example json,
             JSON format
              response if created => {created:true,id:'id',display_id:'disp id'}
              response if failed=> {created:false}
      EOS
      def selfregister
        @device = params[:device]
        @facility = Facility.find_by(id: params[:facility_id])
        @organisation = @facility.organisation
        params[:patient][:reg_hosp_ids] = [@organisation.id.to_s]
        # Last name was not there.
        params[:patient][:fullname] = params[:patient][:firstname] + ' ' + params[:patient][:lastname]
        @patient = Patient.new(selfregister_patient_params)
        if @patient.save
          @patient_identifier = PatientIdentifier.create(patient_id: @patient.id, organisation_id: @organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
          @status_flag = true
        else
          @status_flag = false
        end
        respond_to do |format|
          format.json { render 'register_new_patient', layout: false }
        end
      end

      api :POST, '/api/v1/patients/selfregister', 'Self patient registration tool over tablet'
      formats ['json']
      description <<-EOS
          == Self patient registration tool over tablet
             URL: /api/v1/patients/selfregister
             This is example json,
             JSON format
              response if created => {created:true,id:'id',display_id:'disp id'}
              response if failed=> {created:false}
      EOS
      def selfregister
        @device = params[:device]
        @facility = Facility.find_by(id: params[:facility_id])
        @organisation = @facility.organisation
        params[:patient][:reg_hosp_ids] = [@organisation.id.to_s]
        # Last name was not there.
        params[:patient][:fullname] = params[:patient][:firstname] + ' ' + params[:patient][:lastname]
        @patient = Patient.new(selfregister_patient_params)
        if @patient.save
          @patient_identifier = PatientIdentifier.create(patient_id: @patient.id, organisation_id: @organisation.id.to_s, patient_org_id: CommonHelper.get_patient_org_identifier(current_user))
          @status_flag = true
        else
          @status_flag = false
        end
        respond_to do |format|
          format.json { render 'register_new_patient', layout: false }
        end
      end

      api :POST, '/api/v1/patients/get_patient_list', 'Get full list of patients.'
      formats ['json']
      description <<-EOS
          == Get full list of patients.
             URL: /api/v1/patients/get_patient_list
             no request data required
      EOS
      def get_patient_list
        @patients = Patient.where(:id.in => PatientIdentifier.where(organisation_id: current_user.organisation_id).pluck(:patient_id).to_a)
        respond_to do |format|
          format.json { render 'get_patient_list', layout: false }
        end
      end

      def search_registered_patient; end

      api :POST, '/api/v1/patients/register_new_patient_and_create_appointment', 'Register patient and create appointment on mobile and tablet'
      formats ['json']
      description <<-EOS
          == Register patient and create appointment on mobile and tablet
             URL: /api/v1/patients/register_new_patient_and_create_appointment
             This is example json,
             JSON format to register patient. Ex json: {"registerpatientandappointment": {"patientname": "Max Maniar", "patientgender": "Male or Female", "patientage": 21, "patientdob": "11/09/1977", "smsmobilenumber": "+919900000000", "patientemailaddress": "johndoe@myemail.com" }, "appointment": {"appointmentdate": "05/05/2015", "appointmenttime": "11:31AM", "appointmenttype": "Fresh", "appointmentstatus": 416774000 } }
      EOS
      def register_new_patient_and_create_appointment
        @patient = Patient.create!(patientid: _patientid, hospitalpatientid: _hospitalpatientid, fullname: params[:registerpatientandappointment][:patientname], gender: params[:registerpatientandappointment][:patientgender], displayage: params[:registerpatientandappointment][:patientage], age: params[:registerpatientandappointment][:patientage], dob: params[:registerpatientandappointment][:patientdob], smsmobilenumber: params[:registerpatientandappointment][:smsmobilenumber], email: params[:registerpatientandappointment][:patientemailaddress])
        if @patient
          @appointment = Appointment.create!(appointmentid: _appointmentid, appointmentdate: params[:registerpatientandappointment][:appointmentdate], appointmenttime: params[:registerpatientandappointment][:appointmenttime], visittype: params[:registerpatientandappointment][:appointmenttype], patient_id: @patient.patientid, departmenttype: 440655000, facility_department_id: 66666604, user_id: 999999904, appointmentstatus: 416774000)
          respond_to do |format|
            format.json { render 'register_new_patient_and_create_appointment_success', layout: false }
            # format.json {render :json => {"hgstatus" => 5000 } }
          end
        else
          respond_to do |format|
            format.json { render 'register_new_patient_and_create_appointment_failure', layout: false }
            # format.json {render :json => {"hgstatus" => 10000 } }
          end
        end
      end

      api :GET, '/api/v1/patients/get_summary_for_patient', 'Get patient summary data for a patient on mobile and tablet'
      formats ['json']
      description <<-EOS
          == Get patient summary data for a patient on mobile and tablet
             URL: /api/v1/patients/get_summary_for_patient.
             This is example json,
             Patient id has to be passed. This is example json, patient id is dummy. Ex json: {"patient": {"patientid" : 111111111} }
      EOS
      def get_summary_for_patient
        # @patient = Patient.find_by_patientid(params[:patient][:patientid])
        respond_to do |format|
          format.json { render 'get_patient_summary', layout: false }
        end
      end

      def get_patient_summary_prescriptions
        # @patient = Patient.find_by_patientid(params[:patient][:patientid])
        respond_to do |format|
          format.json { render 'get_patient_summary_prescriptions', layout: false }
        end
      end

      api :POST, '/api/v1/patients/change_profile_pic', 'Change patient profile picture'
      formats ['json']
      description <<-EOS
          == Post Change patient profile picture
             URL: /api/v1/patients/change_profile_pic.
             JSON format to update pic. Ex json: {patient_id:'patient id','asset_path':the image file}

              response if created => {created:true,picthumb: "url",picactual: "url"}
              response if failed=> {created:false}

      EOS
      def change_profile_pic
        @patientasset = Patientasset.new(new_patientasset)
        @status_flag = if @patientasset.save
                         true
                       else
                         false
                       end
        respond_to do |format|
          format.json {}
        end
      end

      api :POST, '/api/v1/patients/save_uploaded_asset', 'Upload patient records by taking a picture over mobile or tablet.'
      formats ['json']
      description <<-EOS
          == Upload patient records by taking a picture over mobile or tablet.
             URL: /api/v1/patients/save_uploaded_asset
             JSON format to update pic. Ex json: {patient_id:'patient id','asset_path':the image file}
              response if created => {created:true,picthumb: "url",picactual: "url"}
              response if failed=> {created:false}
      EOS
      def save_uploaded_asset
        params[:data] = eval(params[:data])
        # params[:data] = JSON.parse(params[:data].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))

        current_user = User.find(params[:data][:current_user_id])
        current_facility = Facility.find(params[:data][:current_facility_id])

        params[:data][:patient_summary_asset_upload][:asset_path] = params[:image]

        params[:data][:patient_summary_asset_upload][:parent_id] = params[:data][:patient_summary_asset_upload][:folder]
        params[:data][:patient_summary_asset_upload][:parent_folder_id] = params[:data][:patient_summary_asset_upload][:folder]
        params[:data][:patient_summary_asset_upload][:original_filename] = params[:data][:patient_summary_asset_upload][:asset_path].original_filename
        @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params(params[:data]))
        if @patient_summary_asset.save!

          if params[:data][:patient_summary_asset_upload][:comment].present?
            @patient_summary_asset.comments.create(comment_text: params[:data][:patient_summary_asset_upload][:comment], created_by: current_user.id, upload_id: @patient_summary_asset.id, investigation_id: params[:data][:patient_summary_asset_upload][:investigation_id])
          end
          @patient_summary_asset.update(organisation_id: current_facility.organisation_id, facility_id: current_facility.id, user_id: current_user.id)
          PatientSummaryAssetUpload.compute_mongoid_for_tags(params[:data][:patient_summary_asset_upload][:tagids], params[:data][:patient_summary_asset_upload][:tagnames], @patient_summary_asset.specialty_id.to_i, current_user.organisation.id.to_s, current_user.id.to_s, @patient_summary_asset.id.to_s)

          @patient_summary_asset_upload = PatientSummaryAssetUpload.find_by(id: @patient_summary_asset.id)
          if @patient_summary_asset_upload.asset_path.file.exists?
            @patient_summary_asset_upload.update(upload_retry_counter: 0)

            respond_to do |format|
              format.json { render 'save_uploaded_asset', layout: false }
            end

          else
            retry_image_upload(@patient_summary_asset_upload, params[:data][:patient_summary_asset_upload][:asset_path], 1)
          end

          # respond_to do |format|
          #   format.js {render "save_uploaded_asset", :layout => false}
          # end
          Patients::Summary::TimelineWorker.call(event_name: 'UPLOAD', sub_event_name: 'ADDED', asset_id: @patient_summary_asset.id, user_id: current_user.id, user_name: current_user.fullname, facility_id: current_facility.id)
        end
      end

      def update_uploaded_asset
        @asset = PatientSummaryAssetUpload.find_by(id: params[:id])
        @asset.update_attributes(update_asset_upload_params)
        @patientfiles = PatientSummaryAssetUpload.where(patient_id: @asset.patient_id, is_deleted: false).order(reported_date: :desc)
        respond_to do |format|
          format.js
        end
        PatientSummaryTimeline.where(event_name: 'UPLOAD', query: { _id: params[:id].to_s }).delete_all
        Patients::Summary::TimelineWorker.call(event_name: 'UPLOAD', sub_event_name: 'ADDED', asset_id: @asset.id, user_id: current_user.id, user_name: current_user.fullname, facility_id: current_facility.id)
      end

      api :POST, '/api/v1/patients/update', 'Update patient details'
      formats ['json']
      description <<-EOS
          == Update patient details,similar to in web.
             URL: /api/v1/patients/update.json?id=<patient id>&current_user_id=<user id>

      EOS
      # def update
      #   current_user = User.find(params[:current_user_id])
      #   @patient = Patients::UpdateService.call(params[:id], params, current_user) # Call Patient UpdateService
      #   respond_to do |format|
      #     format.json{}
      #   end
      # end

      def edit
        @patient = Patient.find_by(id: params[:id])
        @patient_types = PatientType.where(is_active: true, organisation_id: current_user.organisation_id).pluck(:label, :id)
        respond_to do |format|
          format.json {}
        end
      end

      def update
        current_user = User.find(params[:current_user_id])
        @patient = Patients::UpdateService.call(params[:id], params, current_user) # Call Patient UpdateService
        respond_to do |format|
          format.json {}
        end
      end

      private

      # Split up a data uri
      def split_base64(uri_str)
        if uri_str =~ /^data:(.*?);(.*?),(.*)$/
          uri = {}
          uri[:type] = Regexp.last_match(1) # "image/gif"
          uri[:encoder] = Regexp.last_match(2) # "base64"
          uri[:data] = Regexp.last_match(3) # data string
          uri[:extension] = Regexp.last_match(1).split('/')[1] # "gif"
          uri
        end
      end

      # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
      def convert_data_uri_to_upload(obj_hash)
        if obj_hash.try(:match, /^data:(.*?);(.*?),(.*)$/)
          image_data = split_base64(obj_hash)
          image_data_string = image_data[:data]
          image_data_binary = Base64.decode64(image_data_string)

          temp_img_file = Tempfile.new('data_uri-upload')
          temp_img_file.binmode
          temp_img_file << image_data_binary
          temp_img_file.rewind

          img_params = { filename: "data-uri-img.#{image_data[:extension]}", type: image_data[:type], tempfile: temp_img_file }
          uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

          obj_hash = uploaded_file
        end

        obj_hash
      end

      def asset_upload_params(para)
        para.require(:patient_summary_asset_upload).permit(:name, :patient_id, :specialty_id, :parent_id, :reported_date, :reported_time, :asset_path, :investigation_id, :type, :investigation_detail_id, :loinc_code, :parent_folder_id, :category, :opdrecord_id, :tagnames, :original_filename).merge(is_folder: 'N', is_custom: 'Y', is_system_defined: 'N', is_root: 'N')
      end

      def retry_image_upload(psau, file, counter)
        psau.update(asset_path: file, upload_retry_counter: counter)
        if PatientSummaryAssetUpload.find_by(id: psau.id).asset_path.file.exists?
          # render json: {'success': true}
          respond_to do |format|
            format.json { render 'save_uploaded_asset', layout: false }
          end
        else
          counter += 1
          if counter <= 5
            retry_image_upload(psau, file, counter)
          else
            PatientSummaryAssetUpload.find_by(id: psau.id).destroy
            render json: { 'success': false }
          end
        end
      end

      def update_asset_upload_params
        params.require(:patient_summary_asset_upload).permit(:name, :reported_date, :reported_time, :parent_folder_id).merge(is_folder: 'N', is_custom: 'Y', is_system_defined: 'N', is_root: 'N')
      end
      # def asset_upload_params
      #   params.permit(:name,:patient_id, :parent_id, :reported_date, :reported_time, :asset_path, :parent_folder_id).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N")
      # end

      def patient_create_params
        params.permit(:salutation, :firstname, :lastname, :fullname, :gender, :age, :dob, :mobilenumber, :secondarymobilenumber, :contactnumber, :email, :occupation, :address_1, :address_2, :city, :state, :pincode, :blood_group, :maritalstatus, :specialstatus, :emergencycontactname, :emergencymobilenumber, :mr_no, :ip_no, :reg_date, reg_hosp_ids: []) # patientassets_attributes: [:asset_path]
      end

      def selfregister_patient_params
        params.require(:patient).permit!.except(:id)
        ### BELOW LINES WERE ADDED BY PRIYANK. PRIYANK, BELOW LINES ARE NOT NEED, REMOVED BY MOHIT.
        # params.permit(:patient)
        # patient_params = params[:patient]
        # patient_hash = eval patient_params
        # patient_hash[:patient]
      end

      def new_patientasset
        params.permit(:patient_id, :asset_path)
      end
    end
  end
end
