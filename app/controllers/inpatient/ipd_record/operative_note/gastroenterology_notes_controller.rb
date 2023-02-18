class Inpatient::IpdRecord::OperativeNote::GastroenterologyNotesController < Inpatient::IpdRecord::OperativeNotesController
  before_action :specialty_params

  def new
    @url_path = "inpatient_ipd_record_operative_note_#{@speciality_folder_name}_notes_path"
    @procedurenotes = ProcedureNote.where(organisation_id: current_user.organisation_id.to_s, specialty_id: @specialty_id.to_i, is_active: true,
                                          '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    get_advices_list
    super
  end

  def create
    super
  end

  def show
    super
  end

  def edit
    @url_path = "inpatient_ipd_record_operative_note_#{@speciality_folder_name}_note_path"
    @procedurenotes = ProcedureNote.where(organisation_id: current_user.organisation_id, specialty_id: @specialty_id.to_i, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }])
    get_advices_list
    super
  end

  def update
    super
  end

  def print
    super
  end

  private

  def specialty_params
    @specialty = "Gastroenterology"
    @specialty_id = "394584008"
    @speciality_folder_name = "gastroenterology"
  end

  def get_advices_list
    advice_sets = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false, specialty_id: @specialty_id, '$or' => [{ level: "organisation" }, { facility_id: current_facility.id, level: "facility" }, { user_id: current_user.id, level: "user" }]).order(counter: "desc")

    if current_facility.try(:show_language_support)
      @advice_set = advice_sets.map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(" , ")}) by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => "#{p[:id]}" }] }
    else
      @advice_set = advice_sets.map { |p| ["#{p[:name]}  by: #{p[:level].to_s.capitalize}", "#{p[:content]}", { 'data-id' => "#{p[:id]}" }] }
    end
  end

  # super calls inpatient/ipd_record/operative_notes_controller.rb
end
