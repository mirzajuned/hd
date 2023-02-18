# rubocop:disable all
module Mis::ClinicalReports
  class UserWisePatientService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request

        @data_array = []

        unless @request == 'json'
          @data_array << ['PATIENT DETAILS', 'PATIENT ID', 'MR.NO', 'USER ROLE', 'USER', 'APPOINTMENT ID',
                          'PATIENT VISIT', 'APPOINTMENT TYPE', 'SPECIALITY', 'APPOINTMENT DATE']
        end

        aggregation_query = appointment_list_query
        user_list = MisClinical::Opd::OpdClinicalUserwise.collection.aggregate(aggregation_query).to_a[0] || {}
        @user_list = user_list[:user_lists] || []
        total_records = user_list[:user_count] || 0
        user_wise_list
        [@data_array, total_records]
      end

      private

      def user_wise_list
        @user_list.each do |list|
          name = list[:patient_info][:patient_name] || '--'
          phone = list[:patient_info][:patient_mobilenumber] || '--'
          age = list[:patient_info][:patient_age] || '--'
          gender = list[:patient_info][:patient_gender] || '--'
          location = (list[:patient_info][:city] || '__') + '|' + (list[:patient_info][:state] || '__')
          patient_details = name + ' <b>|</b> ' + phone + ' <b>|</b> ' + age.to_s + ' <b>|</b> ' + gender +
                            ' <b>|</b> ' + location
          appointment_user = list[:user_display_fields][:with_user]
          appointment_user_role = list[:user_display_fields][:with_user_role]
          patient_id = list[:patient_info][:patient_display_id]
          patient_mr_no = list[:patient_info][:patient_mr_no]
          appointment_id = list[:user_display_fields][:appointment_display_id]
          patient_vist = list[:user_display_fields][:appointment_type_label]
          appointmenttype = list[:user_display_fields][:appointmenttype]
          speciality = list[:user_display_fields][:specialty_name]
          appointmentdate = list[:user_display_fields][:appointmentdate]&.strftime('%d/%m/%Y')

          @data_array << [patient_details, patient_id, patient_mr_no, appointment_user_role, appointment_user,
                          appointment_id, patient_vist, appointmenttype, speciality, appointmentdate]
        end
      end

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { 'user_display_fields.appointmentdate': -1 } },
          { "$limit": 100000 },
          { "$group": group_options },
          { "$project": project_options }
        ]
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: @mis_params[:facility_id] }
                        else
                          { organisation_id: @mis_params[:organisation_id] }
                        end

        # Date
        match_options = match_options.merge('user_display_fields.appointmentdate': {
                                              "$gte": @mis_params[:start_date].beginning_of_day,
                                              "$lte": @mis_params[:end_date].end_of_day
                                            })
        #
        # user role
        user_role = @mis_params[:user_role]
        match_options = match_options.merge('user_display_fields.with_user_role': patient_type) if user_role.present?

        # Appointment Category
        appointment_type_label = @mis_params[:appointment_type_label]
        if appointment_type_label.present?
          match_options = match_options.merge('user_display_fields.appointment_type_label': appointment_type_label)
        end
        #
        # AppointmentType
        appointmenttype = @mis_params[:appointmenttype]
        if appointmenttype.present?
          match_options = match_options.merge('user_display_fields.appointmenttype': appointmenttype)
        end
        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'zero_plus'
          match_options = match_options.merge('patient_info.age': { "$gte": 0, "$lte": 19 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'twenty_plus'
          match_options = match_options.merge('patient_info.age': { "$gte": 20, "$lte": 39 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'forty_plus'
          match_options = match_options.merge('patient_info.age': { "$gte": 40, "$lte": 59 })
        end
        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'sixty_plus'
          match_options = match_options.merge('patient_info.age': { "$gte": 60, "$lte": 110 })
        end
        # gender type
        apt_status = @mis_params[:patient_gender]
        if apt_status.present?
          match_options = match_options.merge('patient_info.patient_gender': (@mis_params[:patient_gender]).to_s)
        end

        doctor = @mis_params[:consulting_doctor]
        if doctor.present?
          match_options = match_options.merge('user_display_fields.with_user': (@mis_params[:gender_type]).to_s)
        end
        match_options
      end

      def group_options
        { _id: 'null',
          user_lists: { "$push": '$$ROOT' },
          user_count: { "$sum": 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000

        # return
        { user_count: 1,
          user_lists: { "$slice": ['$user_lists', @mis_params[:iDisplayStart].to_i, length] } }
      end
    end
  end
end
