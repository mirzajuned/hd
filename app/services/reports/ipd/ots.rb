class Reports::Ipd::Ots
  def initialize(ot)
    @ot = ot
  end

  def call
    @ot_count = OtSchedule.where(otdate: @ot_schedule.otdate, user_id: @ot_schedule.user_id).count
    @patient_ot = DailyReport.find_by(date: Date.current, facility_id: @ot_schedule.facility_id.to_s, specialty_id: @ot_schedule.specialty_id.to_s)
    if @patient_ot.nil?
      DailyReport.create(create_params)
    else
      @patient_ot.update_attributes(update_params)
    end
  end

  private

  def create_params
    {
      user_id: @ot_schedule.surgeonname.to_s,
      date: @ot_schedule.otdate,
      ot_count: @ot_count,
      month: @ot_schedule.otdate.month,
      year: @ot_schedule.otdate.year,
      organisation_id: @ot_schedule.user.organisation_id.to_s,
      facility_id: @ot_schedule.facility_id.to_s,
      specialty_id: @ot_schedule.specialty_id.to_s
    }
  end

  def update_params
    {
      ot_count: @ot_count
    }
  end

  # Logic to calculate New Old Patient , not required for now
  #   def new_old_patient_in_ipd
  # ipd_patient_ids = Admission.where(user_id: current_user.id,admissiondate: Date.current,facility_id: @admission.facility_id).pluck(:patient_id)
  # ipd_new_patient_count = 0
  # ipd_old_patient_count = 0
  # ipd_patient_ids.each do |pat_id|
  #   pat=Patient.find_by(id: pat_id)
  #   if pat.created_at.to_date == Date.current
  #     ipd_new_patient_count = ipd_new_patient_count+1
  #   else
  #     ipd_old_patient_count = ipd_old_patient_count+1
  #   end
  # end
  # end
end
