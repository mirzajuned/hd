class IcdtreeController < ApplicationController
  respond_to :json

  before_action :authorize

  # Brakeman :: cannot find anywhere in the product, so commenting
  def icdroottree
    r_tb_radiology = ''
    @templatetype = params[:ajax][:templatetype]
    @speciality_folder_name = params[:ajax][:specalityfoldername]
    # r_tb_radiology = Global.send("#{@speciality_folder_name}#{@templatetype}diagnosis").roottreelist
    respond_to do |format|
      format.json { render json: r_tb_radiology }
    end
  end

  # Brakeman :: cannot find anywhere in the product, so commenting
  def icdtraumatree
    r_tb_radiology = ''
    @templatetype = params[:ajax][:templatetype]
    @speciality_folder_name = params[:ajax][:specalityfoldername]
    # r_tb_radiology = Global.send("#{@speciality_folder_name}#{@templatetype}diagnosis").traumatreelist
    respond_to do |format|
      format.json { render json: r_tb_radiology }
    end
  end

  def icdtreekneel2
    tree_location = icd_code_tree_locations(params[:ajax][:tree_location].to_s)
    if tree_location.present?
      template_id = check_tempalte_id(params[:ajax][:template_id].to_i.to_s)
      r_tb_radiology = IcdDiagnosisCode.where(:template_id => template_id, :tree_level => 'L2', :tree_node.in => ['T', 'N'], :tree_location => /^#{tree_location}/i)
      respond_to do |format|
        format.json { render json: r_tb_radiology }
      end
    end
  end

  def icdtreekneel3
    tree_location = icd_code_tree_locations(params[:ajax][:tree_location].to_s)
    if tree_location.present?
      template_id = check_tempalte_id(params[:ajax][:template_id].to_i.to_s)
      r_tb_radiology = IcdDiagnosisCode.where(:template_id => template_id, :tree_level => 'L3', :tree_node.in => ['T'], :tree_location => /^#{tree_location}/i)
      respond_to do |format|
        format.json { render json: r_tb_radiology }
      end
    end
  end

  def fetchlaboratorytests
    laboratorytests = LaboratoryInvestigationData.where(loinc_code: (params[:laboratory][:loinc_code]), facility_id: current_facility.id)
    respond_to do |format|
      format.json { render json: laboratorytests }
    end
  end

  def fetchlaboratoryset
    laboratorysets = UsersLaboratoryList.where(id: (params[:laboratory][:laboratorysetid]))
    respond_to do |format|
      format.json { render json: laboratorysets }
    end
  end

  def getitems
    facility_id = current_facility.id
    area = params[:area]
    @items = []
    case area
    when 'central'
      @inventory_items = Inventory::Item.where(description: /#{Regexp.escape(params[:q])}/i,
                                               facility_id: facility_id, is_deleted: false)
      @inventory_items.each do |new_item|
        item = Struct.new(:id, :category, :description, :dispensing_unit, :dosage, :type, :lot_id,
                          :generic_display_name, :generic_display_ids, :medicine_from).new
        item.id = new_item._id
        item.category = new_item.category
        item.lot_id = Inventory::Item.find(item.id.to_s).lots('stock' => { '$gte' => 1 }, is_deleted: false)
                                     .order(expiry: :asc, created_at: :asc).first.id
        item.description = new_item.description
        item.dispensing_unit = new_item.dispensing_unit if new_item.try(:dispensing_unit)
        item.dosage = new_item.dosage if new_item.try(:dosage)
        item.type = 'NA'
        item.generic_display_name = new_item.generic_display_name
        item.generic_display_ids = new_item.generic_display_ids
        item.medicine_from = 'master'
        @items << item
      end

      if @items.empty?
        @new_items = MedicationList.where(name: /#{Regexp.escape(params[:q])}/i)
        @new_items.each do |new_item|
          item = Struct.new(:id, :description, :dosage, :category, :med_type, :type, :generic_display_name, :generic_display_ids, :medicine_from).new
          item.description = new_item.name
          item.dosage = new_item.presentation
          item.category = 'medication'
          item.id = new_item.id
          item.med_type = new_item.med_type
          item.type = 'NA'
          item.generic_display_name = ''
          item.generic_display_ids = ''
          item.medicine_from = 'medication_list'
          @items << item
        end
      end

    else

      store_id = params[:store_id] || Inventory::Store.where(facility_id: current_facility.id,
                                                             department_id: '284748001', is_disable: false)&.first.try(:id)

      category_ids = Inventory::Store.find_by(id: store_id)&.category_ids || []
      @inventory_variant = Inventory::Item::Variant.where(description: /#{Regexp.escape(params[:q])}/i,
                                                          department_id: '284748001', store_id: store_id,
                                                          is_deleted: false, is_disabled: false,
                                                          organisation_id: current_user.organisation_id,
                                                          :category_id.in => category_ids).limit(20)
                                                   .sort_by! { |i| i.description.try(:downcase) }
      @inventory_variant.each do |inv_var|
        inv_item = Inventory::Item.find_by(id: inv_var.item_id, is_deleted: false, is_disabled: false)
        item = Struct.new(:id, :description, :dosage, :med_type, :category, :type, :stock, :lot_id,
                          :generic_display_name, :generic_display_ids, :medicine_from).new
        item.description = inv_var.description
        item.dosage = inv_var.variant_identifier
        item.category = 'medication'
        item.type = 'P'
        item_lot = Inventory::Item::Lot.where(variant_id: inv_var.id, 'stock' => { '$gte' => 1 }, is_deleted: false)
                                       .order(expiry: :asc, created_at: :asc).first
        item.lot_id = item_lot.try(:id) if item_lot.present?
        if inv_item.try(:integration_identifier).present?
          item.id = inv_item.try(:integration_identifier)
        else
          item.id = inv_var._id
        end
        item.med_type = inv_item.try(:dispensing_unit)
        item.stock = inv_var.try(:stock)
        item.generic_display_name = inv_item.try(:generic_display_name)
        item.generic_display_ids = inv_item.try(:generic_display_ids)
        item.medicine_from = 'master'
        @items << item
      end

      @practice_list = MyPracticeMedicationList.where(name: /#{Regexp.escape(params[:q])}/i, organisation_id: current_user.organisation_id, is_deleted: false, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).limit(50).sort_by! { |i| i.name.try(:downcase) }
      @practice_list.each do |new_item|
        item = Struct.new(:id, :description, :dosage, :med_type, :category, :type, :code, :generic_display_name, :generic_display_ids, :medicine_from).new
        item.id = new_item._id
        item.description = new_item.name
        item.dosage = ''
        item.med_type = new_item.med_type
        item.category = 'medication'
        item.id = new_item&.item_id
        item.type = 'M'
        item.generic_display_name = new_item.contents
        item.generic_display_ids = new_item.id
        item.medicine_from = 'my_practice_medication_list'
        @items << item
      end

      # arr = params[:q].tr('^A-Za-z0-9', ' ').gsub("  "," ").upcase.split(" ")
      # @new_items = CIMSARRAY.select { |set| arr.all? { |t| set[:name].include?(t) } }

      # cims_code_arr = []
      # @new_items.each do |a|
      #  cims_code_arr << a[:cims_id]
      # end

      unless OrganisationsSetting.find_by(organisation_id: current_user.organisation_id).disable_default_medicine
        @cims_medicine = MedicationList.where(name: /#{Regexp.escape(params[:q])}/i).limit(50).sort_by! { |i| i.name.try(:downcase) }
        @cims_medicine.each do |new_item|
          item = Struct.new(:id, :description, :dosage, :med_type, :category, :type, :generic_display_name, :generic_display_ids, :medicine_from).new
          item.id = new_item._id
          item.description = new_item.name
          item.dosage = new_item.presentation
          item.med_type = new_item.med_type
          item.category = 'medication'
          item.type = 'D'
          item.generic_display_name = ''
          item.generic_display_ids = ''
          item.medicine_from = 'medication_list'
          @items << item
        end
      end
    end
  end

  def get_my_laboratory_set
    set = UsersLaboratoryList.find(params[:q].to_s)
    set = FacilityLaboratoryList.find(params[:q].to_s) if set.blank?
    if set.present?
      @lab_list = JSON.parse(set.data)
      @lab = []
      @lab_list.each do |_key, value|
        @lab.push(value)
      end
    else
      head :ok
    end
  end

  def getotinventoryitem
    facility_id = current_facility.id # 309988001_387713003
    @ot_inventory_items = Inventory::Department::Item.where(facility_id: facility_id, department_id: '309988001_387713003')
    @ot_items = []
    @ot_inventory_items.each do |item|
      item_struct = Struct.new(:id, :description, :batch_no, :item_code).new
      item_struct.id = item._id
      item_struct.description = item.description
      item_struct.batch_no = item.lots.pluck(:batch_no).join(',')
      @ot_items << item_struct
    end
    render json: @ot_items.as_json
  end

  def add_diagnosis_icd
    @icd_type = icd_types(params[:icd_type])
    @source = (params[:source] if params[:source].present?) || 'opdrecord'
    @icdcode = params[:ajax][:icdcode]
    @saperatedicdcode = params[:ajax][:saperatedicdcode]
    @entered_by = params[:ajax][:entered_by]
    @entered_by_id = params[:ajax][:entered_by_id]
    @advised_by = params[:ajax][:advised_by]
    @advised_by_id = params[:ajax][:advised_by_id]
    @updated_by = params[:ajax][:updated_by]
    @updated_by_id = params[:ajax][:updated_by_id]
    @diagnosis_comment = params[:ajax][:diagnosis_comment]
    @users_comment = params[:ajax][:users_comment]
    @entry_datetime = params[:ajax][:entry_datetime]
    @entry_time = params[:ajax][:entry_time]
    @updated_datetime = params[:ajax][:updated_datetime]
    @updated_time = params[:ajax][:updated_time]
    @counter = params[:ajax][:counter]
    custom_diagnosis = ['TranslatedIcdDiagnosis','CustomIcdDiagnosis']
    @icddiagnosis = if custom_diagnosis.include?(@icd_type)
                      @icd_type.to_s.constantize.find_by(code: @icdcode.downcase, organisation_id: current_user.organisation_id)
                    else
                      @icd_type.to_s.constantize.find_by(code: @icdcode.downcase)
                    end
    @diagnosis_originalname = @icddiagnosis.originalname
    @diagnosis_fullname = @icddiagnosis.fullname

    respond_to do |format|
      format.js {}
    end
  end

  def edit_diagnosis_icd
    @doctorsarray = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc).pluck(:fullname, :id).map { |elem| elem.map(&:to_s) }
    @elemid = params[:elemid]
    @diagnosis_id = params[:diagnosis_id]
    @record_id = params[:record_id]
    @source = (params[:source] if params[:source].present?) || 'opdrecord'

    if @record_id.present? && @diagnosis_id.present? && @source == 'opdrecord'
      @diagnosis = OpdRecord.find(@record_id.to_s).diagnosislist.find(@diagnosis_id.to_s)
    elsif @record_id.present? && @diagnosis_id.present? && @source == 'inpatient_ipd_record'
      @diagnosis = Inpatient::IpdRecord.find(@record_id.to_s).diagnosislist.find(@diagnosis_id.to_s)
    end

    @diagnosis_comment = params[:diagnosis_comment]
    @users_comment = params[:users_comment]
    @icd_type = icd_types(params[:icd_type])
    custom_diagnosis = ['TranslatedIcdDiagnosis','CustomIcdDiagnosis']
    @icddiagnosis = if custom_diagnosis.include?(@icd_type)
                      @icd_type.to_s.constantize.find_by(code: params[:icdcode], organisation_id: current_user.organisation_id)
                    else
                      @icd_type.to_s.constantize.find_by(code: params[:icdcode])
                    end
    @icddiagnosiscode = @icddiagnosis.code.dup
    @icddiagnosiscode = @icddiagnosiscode.insert(3, '.')
    if @icddiagnosis.root == 0
      @parent_diagnosis = @icddiagnosis
    else
      if @icddiagnosis.has_children == false && @icddiagnosis.has_parent == false # some icddiagnosis don't have parent or children diagnosis and 3 digit, with root 1 and no children
        @parent_diagnosis = @icddiagnosis
      else
        if @icd_type == 'TranslatedIcdDiagnosis'
          @parent_diagnosis = @icddiagnosis
        elsif @icd_type == 'CustomIcdDiagnosis'
          parent_code = @icddiagnosis.parentcodename[0][1]
          @parent_diagnosis = @icd_type.to_s.constantize.find_by(code: parent_code, organisation_id: current_user.organisation_id)
        else
          parent_code = @icddiagnosis.parentcodename[0][1]
          @parent_diagnosis = @icd_type.to_s.constantize.find_by(code: parent_code)
        end
        @children_diagnosis = @icddiagnosis
      end
    end

    # Unspecified fracture of second metacarpal bone right hand initial encounter for closed fracture
  end

  def modal_diagnosis_icd
    @doctorsarray = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc).pluck(:fullname, :id).map { |elem| elem.map(&:to_s) }
    @source = (params[:source] if params[:source].present?) || 'opdrecord'
    @icd_type = icd_types(params[:icd_type])
    custom_diagnosis = ['TranslatedIcdDiagnosis','CustomIcdDiagnosis']
    @icddiagnosis = if custom_diagnosis.include?(@icd_type)
                      @icd_type.to_s.constantize.find_by(code: params[:ajax].downcase, organisation_id: current_user.organisation_id)
                    else
                      @icd_type.to_s.constantize.find_by(code: params[:ajax].downcase)
                    end
    @icddiagnosiscode = @icddiagnosis.code.dup
    @icddiagnosiscode = @icddiagnosiscode.insert(3, '.')
    if @icddiagnosis.root == 0
      @parent_diagnosis = @icddiagnosis
    else
      if @icddiagnosis.has_children == false && @icddiagnosis.has_parent == false # some icddiagnosis don't have parent or children diagnosis and 3 digit, with root 1 and no children
        @parent_diagnosis = @icddiagnosis
      else
        if @icd_type == 'TranslatedIcdDiagnosis'
          @parent_diagnosis = @icddiagnosis
        elsif @icd_type == 'CustomIcdDiagnosis'
          parent_code = @icddiagnosis.parentcodename[0][1]
          @parent_diagnosis = @icd_type.to_s.constantize.find_by(code: parent_code, organisation_id: current_user.organisation_id)
        else
          parent_code = @icddiagnosis.parentcodename[0][1]
          @parent_diagnosis = @icd_type.to_s.constantize.find_by(code: parent_code)
        end
        @children_diagnosis = @icddiagnosis
      end
    end
    # Unspecified fracture of second metacarpal bone right hand initial encounter for closed fracture
  end

  def icd_diagnosis_details
    @icd_diagnosis = IcdDiagnosis.find_by(code: params[:code]) || CustomIcdDiagnosis.find_by(code: params[:code], organisation_id: current_user.organisation_id)
    children_diagnosis = @icd_diagnosis.childrenfullinfo
    @children_diagnosis = []
    children_diagnosis.each do |diagnosis|
      @children_diagnosis << { name: diagnosis.values.flatten[1], code: diagnosis.values.flatten[0] }
    end
    if @icd_diagnosis.has_children
      respond_to do |format|
        format.html { render partial: 'custom_icd_diagnoses/child_icd_diagnosis_details.html.erb' }
      end
    else
      head :ok
    end
  end

  def searchdiagnosis
    @icd_code_array = []

    icddiagnosis = TranslatedIcdDiagnosis.where(fullname: /#{Regexp.escape(params[:q])}/i, organisation_id: current_user.organisation_id, specialty_id: params[:speciality_id], is_deleted: 'false').limit(50)
    icddiagnosis.each do |icd_diagnosis|
      icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
      icd.id = icd_diagnosis._id
      icd.fullname = icd_diagnosis.fullname
      icd.originalname = icd_diagnosis.fullname
      icd.code = icd_diagnosis.code
      icd.icd_type = icd_diagnosis.icd_type

      icd.icd_type_label = if icd_diagnosis.icd_type == 'CustomIcdDiagnosis'
                             'C'
                           else
                             'T'
                           end
      @icd_code_array << icd
    end

    if params[:search_type] != 'custom' && params[:search_type] != 'translated'
      arr = params[:q].tr('^A-Za-z0-9', ' ').gsub('  ', ' ').downcase.split(' ')
      @codearray = ICDARRAY.select { |set| arr.all? { |t| set[:fullname].include?(t) } }

      icd_code_arr = []
      @codearray.each do |a|
        icd_code_arr << a[:code]
      end

      icddiagnosis = IcdDiagnosis.where(:code.in => icd_code_arr).limit(50)
      icddiagnosis.each do |icd_diagnosis|
        icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
        icd.id = icd_diagnosis._id
        icd.originalname = icd_diagnosis.originalname
        icd.fullname = icd_diagnosis.fullname
        icd.code = icd_diagnosis.code
        icd.icd_type = 'IcdDiagnosis'
        icd.icd_type_label = 'I'
        @icd_code_array << icd
      end
    end

    if params[:search_type] == 'translated'
      icddiagnosis = IcdDiagnosis.where(fullname: /#{Regexp.escape(params[:q])}/i, root: 1).limit(50)
      icddiagnosis.each do |icd_diagnosis|
        icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
        if icd_diagnosis.has_laterality == true
          icd.id = icd_diagnosis._id
          icd.originalname = icd_diagnosis.originalname
          icd.fullname = icd_diagnosis.parentcodename.flatten[0]
          icd.code = icd_diagnosis.parentcodename.flatten[1]
          icd.icd_type = 'IcdDiagnosis'
          icd.icd_type_label = 'I'
          @icd_code_array << icd
        else
          icd.id = icd_diagnosis._id
          icd.originalname = icd_diagnosis.originalname
          icd.fullname = icd_diagnosis.fullname
          icd.code = icd_diagnosis.code
          icd.icd_type = 'IcdDiagnosis'
          icd.icd_type_label = 'I'
          @icd_code_array << icd
        end
      end
    end

    icddiagnosis = CustomIcdDiagnosis.where("$or": [{ fullname: /#{Regexp.escape(params[:q])}/i }, { code: /#{Regexp.escape(params[:q])}/i }], organisation_id: current_user.organisation_id, specialty_id: params[:speciality_id], is_deleted: 'false').limit(50)
    icddiagnosis.each do |icd_diagnosis|
      icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
      icd.id = icd_diagnosis._id
      icd.fullname = icd_diagnosis.fullname
      icd.originalname = icd_diagnosis.originalname
      icd.code = icd_diagnosis.code
      icd.icd_type = icd_diagnosis.icd_type
      icd.icd_type_label = 'C'
      @icd_code_array << icd
    end

    icddiagnosis = SynonymIcdDiagnosis.where(abbrevated_name: /#{Regexp.escape(params[:q])}/i, organisation_id: current_user.organisation_id, specialty_id: params[:speciality_id], is_deleted: 'false').limit(50)
    icddiagnosis.each do |icd_diagnosis|
      icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
      icd.id = icd_diagnosis._id
      icd.fullname = icd_diagnosis.fullname
      icd.originalname = icd_diagnosis.fullname
      icd.code = icd_diagnosis.code
      icd.icd_type = icd_diagnosis.icd_type

      icd.icd_type_label = if icd_diagnosis.icd_type == 'CustomIcdDiagnosis'
                             'C'
                           else
                             'I'
                           end
      @icd_code_array << icd
    end
  end

  def geticdattributes
    @icddiagnosiscode = params[:ajax][:icddiagnosiscode]
    @specialty_id = params[:ajax][:specialty_id]
    @template_id = params[:ajax][:template_id]
    @icddiagnosis = IcdDiagnosisCodeAttribrute.where(computed_attribute_code: @icddiagnosiscode, attribute_code_position: (@icddiagnosiscode.length.to_i + 1), specialty_id: @specialty_id.to_i, template_id: @template_id.to_i).order(attribute_code_position: :asc)
    # if @icddiagnosiscode.length < 5
    #   @icddiagnosis = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => @icddiagnosiscode, :attribute_code_position => 5, specialty_id: @specialty_id.to_i, template_id: @template_id.to_i).order(attribute_code_position: :asc)
    # elsif @icddiagnosiscode.length == 5
    #   @icddiagnosis = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => @icddiagnosiscode, :attribute_code_position => 6, specialty_id: @specialty_id.to_i, template_id: @template_id.to_i).order(attribute_code_position: :asc)
    # elsif @icddiagnosiscode.length == 6
    #   @icddiagnosis = IcdDiagnosisCodeAttribrute.where(:computed_attribute_code => @icddiagnosiscode, :attribute_code_position => 7, specialty_id: @specialty_id.to_i, template_id: @template_id.to_i).order(attribute_code_position: :asc)
    # end
    respond_to do |format|
      format.json { render 'icdattributes' }
    end
  end

  def getradiologyattributes
    @radiologycode = params[:ajax][:radiologycode]
    @radiology = RadiologyTemp.where(radiologycode: @radiologycode, position: 2..3)
    respond_to do |format|
      format.json { render 'radiologyattributes' }
    end
  end

  def get_radiology_attributes
    if params[:ajax].present?
      investigationid = params[:ajax][:investigationid]
      @investigations = if params[:custom] == 'true'
                          CustomRadiologyInvestigation.where(investigation_id: investigationid.to_s)
                        else
                          RadiologyInvestigationData.where(investigation_id: investigationid.to_i)
                        end

      respond_to do |format|
        format.json { render 'get_radiology_attributes' }
      end
    else
      head :ok
    end
  end

  def get_custom_radiology_attributes
    @custom_radio_investigation = CustomRadiologyInvestigation.find_by(investigation_id: params[:ajax][:investigation_id].to_s)

    render json: @custom_radio_investigation.as_json
  end

  private

  def icd_types(icd_type)
    ['TranslatedIcdDiagnosis', 'SynonymIcdDiagnosis', 'CustomIcdDiagnosis', 'IcdDiagnosis', 'IcdDiagnosisCode', 'TopOrthoIcdDiagnosis', 'TopIcdDiagnosis'].select{|i_type| i_type == icd_type}.first
  end
  # EOF icd_types
end
