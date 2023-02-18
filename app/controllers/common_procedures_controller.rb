class CommonProceduresController < ApplicationController
  before_action :authorize

  def search
    @procedures_array = []
    disable_default_procedure = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id).try(:disable_default_procedure)
    unless disable_default_procedure
      @common_procedures = CommonProcedure.where(speciality_id: params[:speciality_id], "$or": [{ name: /#{Regexp.escape(params[:search])}/i }, { code: /#{Regexp.escape(params[:search])}/i }]).limit(50)

      @common_procedures.each do |procedure|
        procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
        procedure_struc.id = procedure._id
        procedure_struc.name = procedure.name
        procedure_struc.code = procedure.code
        procedure_struc.procedure_type = 'CommonProcedure'
        procedure_struc.procedure_type_label = 'C'
        @procedures_array << procedure_struc
      end
    end

    # @custom_common_procedures = CustomCommonProcedure.where(speciality_id: params[:speciality_id], "$or" => [{ name: /#{Regexp.escape(params[:search])}/i }, { code: /#{Regexp.escape(params[:search])}/i }], organisation_id: current_user.organisation_id.to_s, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' }, { level: 'organisation' }], is_deleted: 'false').limit(50)

    @custom_common_procedures = CustomCommonProcedure.where(speciality_id: params[:speciality_id], "$or" => [{ name: /#{Regexp.escape(params[:search])}/i, facility_id: current_facility.id.to_s, level: 'facility' },{ name: /#{Regexp.escape(params[:search])}/i, level: 'organisation' }, { code: /#{Regexp.escape(params[:search])}/i, facility_id: current_facility.id.to_s, level: 'facility' }, { code: /#{Regexp.escape(params[:search])}/i, level: 'organisation' }], organisation_id: current_user.organisation_id.to_s, is_deleted: 'false').limit(50)


    # @custom_common_procedures = CustomCommonProcedure.where(speciality_id: params[:speciality_id], name: /#{Regexp.escape(params[:search])}/i , organisation_id: current_user.organisation_id.to_s, '$or' => [{ facility_id: current_facility.id.to_s, level: 'facility' }, { level: 'organisation' }], is_deleted: 'false').limit(50)

    @custom_common_procedures.each do |procedure|
      procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
      procedure_struc.id = procedure._id
      procedure_struc.name = procedure.name
      procedure_struc.code = procedure.code
      procedure_struc.procedure_type = 'CustomCommonProcedure'
      procedure_struc.procedure_type_label = 'CC'
      @procedures_array << procedure_struc
    end

    unless disable_default_procedure
      @synonym_procedures = SynonymCommonProcedure.where(specialty_id: params[:speciality_id], name: /#{Regexp.escape(params[:search])}/i, organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)

      @synonym_procedures.each do |procedure|
        procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
        procedure_struc.id = procedure._id
        procedure_struc.name = procedure.name
        procedure_struc.code = procedure.code
        procedure_struc.procedure_type = procedure.procedure_type
        procedure_struc.procedure_type_label = if procedure.procedure_type == 'CommonProcedure'
                                                 'C'
                                               else
                                                 'CC'
                                               end
        @procedures_array << procedure_struc
      end
    end

    unless disable_default_procedure
      @translated_procedures = TranslatedCommonProcedure.where(speciality_id: params[:speciality_id], name: /#{Regexp.escape(params[:search])}/i, organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)

      @translated_procedures.each do |procedure|
        procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
        procedure_struc.id = procedure._id
        procedure_struc.name = procedure.name
        procedure_struc.code = procedure.code
        procedure_struc.procedure_type = procedure.procedure_type
        procedure_struc.procedure_type_label = if procedure.procedure_type == 'CommonProcedure'
                                                 'C'
                                               else
                                                 'T'
                                               end
        @procedures_array << procedure_struc
      end
    end
  end

  def get_procedure_details
    @procedure_type = get_procedure_type(params[:procedure_type])
    @from = params[:from]
    if @procedure_type.present? && params[:code].present?
      @doctors_array = User.where(facility_ids: current_facility.id, role_ids: 158965000, is_active: true).sort(fullname: :asc).pluck(:fullname, :id).map { |elem| elem.map(&:to_s) }
      @source = params[:source].present? ? params[:source] : 'opdrecord'
      @id = params[:id]
      @flag = params[:flag]
      @counter = params[:counter]
      @status = params[:status] || 'A'
      @side_id = params[:side_id] || ''
      @procedure_comment = params[:procedure_comment] || ''
      @users_comment = params[:users_comment] || ''

      if @procedure_type == "CustomCommonProcedure"
        @common_procedure = @procedure_type.constantize.find_by(code: params[:code], organisation_id: current_facility.try(:organisation_id).to_s)
      else
        @common_procedure = @procedure_type.constantize.find_by(code: params[:code])
      end

      admission_id = params[:admission_id]
      @admission_doctor = admission_id.present? ? Admission.find_by(id: admission_id).try(:doctor) : current_user.id
      @performed_by_id = params[:performed_by_id]
      @performed_datetime = params[:performed_datetime]
    else
      head :ok
    end
  end

  def append_procedure_details
    @procedure_type = get_procedure_type(params[:procedure][:procedure_type].to_s)
    @source = params[:procedure][:source]
    @speciality_id = params[:procedure][:speciality_id]
    @procedure = params[:procedure]
    @counter = @procedure[:count]
    @from = params[:from]
    @performed_by = User.find_by(id: @procedure[:performed_by_id]).try(:fullname) if @procedure[:stage] == 'P'
    if @procedure_type == 'CustomCommonProcedure'
      # @common_procedure = eval(@procedure_type).find_by(code: @procedure[:code], organisation_id: current_facility.try(:organisation_id).to_s)
      @common_procedure = @procedure_type.constantize.find_by(code: @procedure[:code], organisation_id: current_facility.try(:organisation_id).to_s)
    else
      # @common_procedure = eval(@procedure_type).find_by(code: @procedure[:code])
      @common_procedure = @procedure_type&.constantize.find_by(code: @procedure[:code])
    end
    if @from == "counselling_record"
      @order_advised = Order::Advised.new(@procedure.permit!.to_h.except(:count,:performed_by_id,:performed_datetime, :performed_date, :performed_time, :procedure_comment,:users_comment))
      @order_advised.assign_attributes(procedure_id: @procedure[:code], advised_by: @procedure[:entered_by], advised_by_id: @procedure[:entered_by_id], advised_at_facility: @procedure[:entered_at_facility], advised_at_facility_id: @procedure[:entered_at_facility_id], advised_datetime: @procedure[:entered_datetime], procedurestage: 'Advised', procedureside: @procedure[:side], status: 'Advised', procedurename: @common_procedure.name, type: 'procedures', quantity: 1)
      @counselling_record = Order::CounsellingRecord.build({order_advised_id: @order_advised.id.to_s})
    end
  end

  def get_procedure_type(procedure_type)
    ['CustomCommonProcedure', 'CommonProcedure', 'SynonymCommonProcedure', 'TranslatedCommonProcedure'].select{|procedure| procedure == procedure_type}.first
  end
  # EOF get_procedure_type
end
