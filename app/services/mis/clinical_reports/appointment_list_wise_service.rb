# 2  Metrics/AbcSize
# 1  Metrics/CyclomaticComplexity
# 1  Metrics/MethodLength
# 1  Metrics/PerceivedComplexity
# --
# 5  Total
module Mis::ClinicalReports
  class AppointmentListWiseService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @loction_type = mis_params[:loc_type].blank? ? 'city' : mis_params[:loc_type]
        @data_array = []
        unless @request == 'json'
          @data_array << ['DATE', 'PATIENT NAME', 'MOBILE', 'AGE/GENDER', 'PATIENT ID',
                          'APPOINTMENT ID', 'CURRENT STATE', @loction_type.upcase, 'TOTAL TIME(MINUTES)']
        end

        appointment_lists = AppointmentListView.collection.aggregate(appointment_list_query).to_a[0] || {}

        @appointment_lists = appointment_lists[:appointment_lists] || []
        total_records = appointment_lists[:appointment_count].to_i

        appointment_ids = @appointment_lists.map { |al| al[:appointment_id].to_s }
        get_workflow_fields(appointment_ids) if appointment_ids.present? && appointment_ids.count > 0

        appointment_list_data

        [@data_array, total_records]
      end

      private

      def appointment_list_data(_date = '')
        @appointment_lists.try(:each) do |appointment_list|
          workflow = @workflow_fields.find { |w| w[:appointment_id].to_s == appointment_list[:appointment_id].to_s }

          appointment_date = appointment_list[:appointment_date].to_date.try(:strftime, '%d/%m/%Y')
          display_date = appointment_date

          patient_name = appointment_list[:patient_name].to_s
          patient_age = appointment_list[:patient_age].present? ? appointment_list[:patient_age].to_s.tr('-', ' ') : '-'
          patient_gender = appointment_list[:patient_gender].present? ? appointment_list[:patient_gender].to_s : '-'
          patient_age_gender = patient_age + '/' + patient_gender
          patient_display_id = appointment_list[:patient_display_id]
          patient_mr_no = appointment_list[:patient_mr_no].present? ? "<br/>#{appointment_list[:patient_mr_no]}" : ''
          patient_id = patient_display_id.to_s + patient_mr_no.to_s
          appointment_id = appointment_list[:appointment_display_id]
          appointment_state = appointment_list[:current_state]
          mobile = appointment_list[:mobilenumber] || '--'
          appointment_location = appointment_list[:loc_type].present? ? appointment_list[:loc_type] : '--'
          total_transition_time = workflow.present? ? workflow[:total_transition_time] : '-'

          @data_array << [display_date, patient_name, mobile, patient_age_gender, patient_id,
                          appointment_id, appointment_state, appointment_location, total_transition_time]
          date = appointment_date
        end
        # end
      end

      def appointment_list_query
        # AppointmentList Query
        aggregation_query = [
          { "$match": match_options },
          { "$sort": { appointment_date: -1 } },
          { "$limit": 100000 },
          { "$group": group_options },
          { "$project": project_options }
        ]
        aggregation_query
      end

      def match_options
        # Facility/Organisation
        match_options = if @mis_params[:facility_id].present?
                          { facility_id: BSON::ObjectId(@mis_params[:facility_id]) }
                        else
                          { organisation_id: BSON::ObjectId(@mis_params[:organisation_id]) }
                        end

        # Date
        match_options = match_options.merge(appointment_date: { "$gte": @mis_params[:start_date].beginning_of_day,
                                                                "$lte": @mis_params[:end_date].end_of_day })

        # Patient Type
        patient_type = @mis_params[:patient_type]
        match_options = match_options.merge(patient_type: patient_type) if patient_type.present?

        # State
        if @mis_params[:current_state].present?
          match_options = if @mis_params[:current_state] == 'Incomplete'
                            match_options.merge(current_state: { "$in": ['Waiting', 'Engaged', 'Incompleted'] })
                          else
                            match_options.merge(current_state: @mis_params[:current_state])
                          end
        end
        # Appointment Category
        category = @mis_params[:appointment_category_label]
        match_options = match_options.merge(appointment_category_label: category) if category.present?

        # AppointmentType
        appointment_type = @mis_params[:appointmenttype]
        match_options = match_options.merge(appointmenttype: appointment_type) if appointment_type.present?

        # Consultancy Type
        consultancy_type = @mis_params[:consultancy_type]
        match_options = match_options.merge(consultancy_type: consultancy_type) if consultancy_type.present?

        # location type
        location_type = @mis_params[:loc_type]
        match_options = match_options.merge(@mis_params[:loc_type].to_sym => @mis_params[:loc]) if location_type.present?
        match_options = match_options.merge(current_state: { "$nin": ['Deleted'] })

        # age type
        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'nil_count'
          match_options = match_options.merge(age: nil)
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'zero_plus'
          match_options = match_options.merge(age: { "$gte": 0, "$lte": 19 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'twenty_plus'
          match_options = match_options.merge(age: { "$gte": 20, "$lte": 39 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'forty_plus'
          match_options = match_options.merge(age: { "$gte": 40, "$lte": 59 })
        end

        if @mis_params[:age_type].present? && @mis_params[:age_type] == 'sixty_plus'
          match_options = match_options.merge(age: { "$gte": 60, "$lte": 110 })
        end
        # gender type
        apt_status = @mis_params[:gender_type]
        match_options = match_options.merge(patient_gender: (@mis_params[:gender_type]).to_s) if apt_status.present?
        # appt status
        apt_status = @mis_params[:appointment_status]
        match_options = match_options.merge(appointment_type: @mis_params[:appointment_status]) if apt_status.present?
        match_options
      end

      def group_options
        { _id: 'null',
          appointment_lists: { "$push": { appointment_id: '$appointment_id', appointment_date: '$appointment_date',
                                          patient_name: '$patient_name', patient_age: '$patient_age',
                                          patient_gender: '$patient_gender', patient_display_id: '$patient_display_id',
                                          patient_mr_no: '$patient_mr_no', mobilenumber: '$patient_mobilenumber',
                                          appointment_display_id: '$appointment_display_id',
                                          current_state: '$current_state', loc_type: "$#{@loction_type}" } },
          appointment_count: { "$sum": 1 } }
      end

      def project_options
        length = @request == 'json' ? @mis_params[:iDisplayLength].to_i : 100000

        # return
        { appointment_count: 1,
          appointment_lists: { "$slice": ['$appointment_lists', @mis_params[:iDisplayStart].to_i, length] } }
      end

      def get_workflow_fields(appointment_ids)
        clinical_workflows = OpdClinicalWorkflow.where(:appointment_id.in => appointment_ids)
        @workflow_fields = clinical_workflows.map do |workflow|
          total_transition_time = workflow.state == 'not_arrived' || workflow.state == 'cancelled' ? 'NA' : workflow.total_transition_time_in_org&.upcase

          total_transition_time = ms_from_string(total_transition_time) unless @request == 'json' || total_transition_time == 'NA'
          { appointment_id: workflow.appointment_id.to_s, total_transition_time: total_transition_time }
        end
      end

      def ms_from_string(total_transition_time)
        time_ary = total_transition_time.split(' ').map(&:to_i)
        millisec = 0
        if time_ary.count > 2 #H and M
          hour = time_ary[0]
          min = time_ary[2]
          millisec = (hour * 1000 * 3600) + (min * 1000 * 60)
        elsif time_ary.count == 2 #only M
          min = time_ary[0]
          millisec = (min * 1000 * 60)
        else
          millisec = 0
        end
        millisec = (millisec / 60000) rescue 0
        millisec
      end
      # EOF ms_from_string
    end
  end
end
