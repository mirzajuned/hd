class Mis::Clinical::Opd::ExtractDoctorPatientReferralWorker
  
  def initialize(record_id)
    @record_id = record_id
  end

  def call
    options_array = []
    options_array = process_request(@record_id)
    process_data(options_array)
  end

  private

  def process_request(record_id)
    Mis::ClinicalReports::Opd::DoctorPatientReferralSummaryService.format_data_before_save(record_id)
  end

  def process_data(options_array)
    Mis::ClinicalReports::Opd::DoctorPatientReferralSummaryService.process_and_save(options_array)
  end
end