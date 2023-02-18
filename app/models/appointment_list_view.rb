class AppointmentListView
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Attributes::Dynamic

  field :patient_name, type: String
  field :patient_id, type: BSON::ObjectId
  field :patient_display_id, type: String
  field :patient_mr_no, type: String
  field :patient_age, type: String
  field :patient_gender, type: String
  field :patient_type, type: String
  field :patient_type_color, type: String
  field :facility_id, type: BSON::ObjectId
  field :scheduling_user, type: String
  field :scheduling_user_id, type: BSON::ObjectId
  field :consulting_doctor, type: String
  field :consulting_doctor_id, type: BSON::ObjectId
  field :appointment_display_id, type: String
  field :scheduled_date, type: Date
  field :scheduled_time, type: Time
  field :appointment_date, type: Date
  field :appointment_start_time, type: Time
  field :appointment_engaged_time, type: Time
  field :appointment_end_time, type: Time
  field :appointment_type, type: String
  field :appointment_type_color, type: String
  field :current_state, type: String, default: "Scheduled"
  field :current_state_color, type: String
  field :dilation_start_time, type: Time
  field :dilation_end_time, type: Time
  field :dilation_state, type: String
  field :dilation_state_color, type: String
  field :organisation_id, type: BSON::ObjectId

  field :token_number, type: String

  field :intra_referral_id, type: BSON::ObjectId
  field :referral, type: Boolean, default: false
  field :referral_opd_record, type: BSON::ObjectId
  field :referral_type, type: String
  field :referring_doctor, type: String
  field :referral_note, type: String
  field :referee_doctor, type: String
  field :refer_to_facility_name, type: String
  field :refer_from_facility_name, type: String
  field :referral_created_on, type: Date # date on which referral is created
  field :referral_details, type: Hash
  field :appointment_type_comment, type: String
  field :is_migrated, type: Boolean, default: true
  field :appointment_category_label, type: String
  field :appointment_category_color, type: String
  field :appointmenttype, type: String

  field :city, type: String
  field :pincode, type: String
  field :state, type: String
  field :district, type: String
  field :commune, type: String
  field :patient_mobilenumber, type: String
  field :age, type: Integer

  field :specialty_id, type: String
  field :specialty_name, type: String

  field :consultancy_type, type: String # h1.001 -> Free, h1.002 -> Paid
  field :consultancy_type_reason, type: String

  field :opd_consultation_taken, type: Boolean, default: false
  field :opd_consultation_amount, type: String
  field :opd_consultation_bill_type, type: String
  field :opd_consultation_bill_display_id, type: String

  belongs_to :appointment

  index({ facility_id: 1 }, { background: true })

  def patient_time
    if self.current_state == "Waiting"
      @waiting_time = self.time_difference(Time.current, self.appointment_start_time)
    elsif self.current_state == "Engaged"
      @waiting_time = self.time_difference(self.appointment_engaged_time, self.appointment_start_time)
      @engaged_time = self.time_difference(Time.current, self.appointment_engaged_time)
    elsif self.current_state == "Completed"
      if self.appointment_engaged_time.nil?
        @waiting_time = self.time_difference(self.appointment_end_time, self.appointment_start_time)
      else
        @waiting_time = self.time_difference(self.appointment_engaged_time, self.appointment_start_time)
        @engaged_time = self.time_difference(self.appointment_end_time, self.appointment_engaged_time)
      end
    end
    return @waiting_time, @engaged_time
  end

  def time_difference(time1, time2)
    if (time1.present? && time2.present?)
      time_total_sec = (time1 - time2).abs
      time_in_hours = (((time_total_sec) / 60) / 60).to_i
      time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
      @time = ""
      if time_in_hours != 0
        @time = @time + time_in_hours.abs.to_s + " Hrs "
      end
      @time = @time + time_in_minutes.abs.to_s + " Mins "
    else
      @time = "0 Hrs"
    end
    return @time
  end

  def time_difference_sec(time1, time2)
    if (time1.present? && time2.present?)
      time_total_sec = (time1 - time2).abs
      time_in_hours = (((time_total_sec) / 60) / 60).to_i
      time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
      time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
      # @time = ""
      # if time_in_hours != 0
      #   @time = @time + time_in_hours.abs.to_s + " Hrs "
      # end
      # @time = @time + time_in_minutes.abs.to_s + " Mins "
    else
      time_in_seconds = "0"
    end
    return time_in_seconds.abs.to_s
  end
end

# db.appointment_list_views.createIndex({"organisation_id": 1 });
