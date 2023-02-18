class Mis::Clinical::ExtractDiagnosesWorker
  def initialize(record_id, from_department, created_from_form_name, start_date=nil, end_date=nil, entered_from=nil)
    @record_id = record_id
    @from_department = from_department
    @created_from_form_name = created_from_form_name
    @start_date = start_date
    @end_date = end_date
    @entered_from = entered_from
  end

  def call
    options_array = process_request(@record_id, @from_department, @created_from_form_name, @start_date, @end_date, @entered_from)
    process_data(options_array)
  end

  private

  def process_request(record_id, from_department, created_from_form_name, start_date, end_date, entered_from)
    Mis::ClinicalReports::DiagnosisSummaryService.format_data_before_save(
      record_id, from_department, created_from_form_name, start_date, end_date, entered_from
    )
  end

  def process_data(options_array)
    Mis::ClinicalReports::DiagnosisSummaryService.process_and_save(options_array)
  end
end
