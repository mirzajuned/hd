class AdverseEvents::SendMailAdverseEventService
  class << self
    def call(adverse_event_id, current_user)
      @description = []
      @adverse_event = AdverseEvent.find_by(id: adverse_event_id)
      @recipients = AdverseEventsMailSetting.where(organisation_id: @adverse_event.organisation_id, send_mail: true, is_removed: false)
      @facility = Facility.find_by(id: @adverse_event.facility_id)
      @patient = Patient.find_by(id: @adverse_event.patient_id)
      @record_mail_sets = RecordMailerSet.where(user_id: current_user.id)
      @email_tracker = MailRecordTracker.new
      @recipient_mail = @recipients.collect(&:recipient_mail).join(",")
      @recipient_name = @recipients.collect(&:recipient_name).join(",")
      @organisation_id = @adverse_event.organisation_id
      @organisation= Organisation.find_by(id: @organisation_id)
      @record_details = { record_name: 'AdverseEvent', record_id: @adverse_event.id.to_s, record_model: 'AdverseEvent' }
      @sender_details = { sender_name: current_user.fullname, sender_id: current_user.id.to_s, sender_role: current_user.primary_role }
      @receiver_details = { patient_email: @recipient_mail, patient_name: @recipient_name, patient_id: @patient.id.to_s }
      @facility_details = { facility_name: @facility.name, facility_id: @facility.id.to_s }

      if @facility.country_id == 'VN_254'
        @subject = @adverse_event.try(:type).titleize + ' Event Reported' + ' |' + ' ' + @facility.name + '(' + @facility.abbreviation + ')'+ ',' + @facility.city.titleize + ',' + @facility.commune.titleize + ',' + @facility.district.titleize
      else
        @subject = @adverse_event.try(:type).titleize + ' Event Reported' + ' |' + ' ' + @facility.name + '(' + @facility.abbreviation + ')'+ ',' + @facility.city.titleize + ',' + @facility.state.titleize
      end

      @patient_name = @patient.firstname.titleize.slice(0,3) + '******'
      @patient_age =  if @patient.age.present?
                        @patient.age
                      else
                        '--'
                      end

      @patient_gender = if @patient.gender.present?
                          @patient.gender
                        else
                          '--'
                        end
      @patient_mobilenumber = @patient.mobilenumber.slice(0,3) + '********'
      @key = @adverse_event.try(:event_description)
      if @key.present?
        if @adverse_event[:type] == 'major'
          @description << YAML.load_file("#{Rails.root}/config/mis/adverse_event_description.yml")[@key]
        end
        if ['critical', 'minor'].include?(@adverse_event[:type])
          fields = YAML.load(File.read("#{Rails.root}/config/global/adverse_events.yml"))['default']["#{@adverse_event[:type]}_options"].values.flatten
          @description << (Hash[fields.map{|e| [e['value'], e['name']]}] || {}).with_indifferent_access[@key]
        end

        if ['patient_distress', 'postop_inflammation', 'aqueous_meets_vitreous', 'surgical_complications_repeat_surgeries', 'wrong_iol_power', 'rescheduling_cancelling_surgery', 'optical_related'].include?(@key)
          second_stage_key = @key + '_one'
        end

        if second_stage_key.present?
          @second_stage_value = @adverse_event.send(second_stage_key)
        else
          @second_stage_value = ''
        end

        if second_stage_key == 'surgical_complications_repeat_surgeries_one'
          third_stage_key = 'major_' + @second_stage_value if @second_stage_value.present?
        end

        if third_stage_key.present?
          @third_stage_value = @adverse_event.send(third_stage_key)&.split(',')&.join(" , ")
        else
          @third_stage_value = ''
        end

        if @second_stage_value.present? && !@third_stage_value.present?
          @event_description = @description.join('') + '<br>' + @second_stage_value.titleize
        elsif @second_stage_value.present? && @third_stage_value.present?
          @event_description = @description.join('') + '<br>' + @second_stage_value.titleize + '<br>' + @third_stage_value.titleize
        else
          @event_description = @description.join('')
        end
        comment_key = @key + '_comment'
        @comment = @adverse_event.try(comment_key).titleize
      end
      @mail_text = "<div style='margin-left: 13px;'>
                      <table class='table table-bordered'>
                        <tbody>
                          <tr style='text-align: left;'>
                            <th>Patient Name:</th>
                            <td>#{@patient_name}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>Age/Gender:</th>
                            <td>#{@patient_age} / #{@patient_gender}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>Mobile No.:</th>
                            <td>#{@patient_mobilenumber}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>SubSpeciality:</th>
                            <td>#{@adverse_event.try(:sub_speciality).titleize}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>Category:</th>
                            <td>#{@adverse_event.try(:type).titleize}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>Description:</th>
                            <td>#{@event_description}</td>
                          </tr>
                          <tr style='text-align: left;'>
                            <th>Comment:</th>
                            <td>#{@comment}</td>
                          </tr>
                        </tbody>
                      </table>
                      <br/><br/>
                      <a href='#{Global.send('healthgraph')[Rails.env]['host']}/mis/new_clinical_reports/reports_view?group=outpatient&title=patient_adverse_event'>Link to Adverse Event Report</a>
                    </div>"

      @email_tracker = MailRecordTracker.new(organisation_id: @organisation_id, record_details: @record_details, sender_details: @sender_details, receiver_details: @receiver_details, facility_details: @facility_details, mail_text: @mail_text, subject: @subject)
      @email_tracker.save!
      RecordsMailer.send_mail(id: @email_tracker.id, patient_id: @patient.id, facility_id: @facility.id).deliver_now
    end
  end
end