module Api
  module V1
    module Ehr
      class CommonSearchController < ApiApplicationController
        respond_to :json

        before_action :authorize_token

        # Brakeman :: cannot find anywhere in the product, so commenting
        def icdroottree
          @templatetype = params[:ajax][:templatetype]
          @speciality_folder_name = params[:ajax][:specalityfoldername]
          r_tb_radiology = Global.send("#{@speciality_folder_name}#{@templatetype}diagnosis").roottreelist
          respond_to do |format|
            format.json { render json: r_tb_radiology }
          end
        end

        # Brakeman :: cannot find anywhere in the product, so commenting
        def icdtraumatree
          @templatetype = params[:ajax][:templatetype]
          @speciality_folder_name = params[:ajax][:specalityfoldername]
          r_tb_radiology = Global.send("#{@speciality_folder_name}#{@templatetype}diagnosis").traumatreelist
          respond_to do |format|
            format.json { render json: r_tb_radiology }
          end
        end

        def icdtreekneel2
          # r_tb_radiology = IcdDiagnosisCode.where("tree_node in ('T', 'N') and tree_level = 'L2' and SUBSTRING_INDEX(tree_location, '.', 2) = '#{params[:ajax][:tree_location]}' and template_id = #{params[:ajax][:template_id].to_i}")
          r_tb_radiology = IcdDiagnosisCode.where(:template_id => params[:ajax][:template_id].to_i.to_s, :tree_level => 'L2', :tree_node.in => ['T', 'N'], :tree_location => /^#{params[:ajax][:tree_location]}/i)
          # r_tb_radiology = IcdDiagnosisCode.where("tree_node in ('T', 'N') and tree_level = 'L2' and SUBSTRING_INDEX(tree_location, '.', 2) = '#{params[:ajax][:tree_location]}' and template_id = #{params[:ajax][:template_id].to_i}")
          respond_to do |format|
            format.json { render json: r_tb_radiology }
          end
          # tree_location = icd_code_tree_locations(params[:ajax][:tree_location].to_s)
          # if tree_location.present?
            # template_id = check_tempalte_id(params[:ajax][:template_id].to_i.to_s)
            # r_tb_radiology = IcdDiagnosisCode.where(template_id: template_id, tree_level: 'L2', :tree_node.in => ['T', 'N'], :tree_location => /^#{tree_location}/i)
            # respond_to do |format|
            #   format.json { render json: r_tb_radiology }
            # end
          # end
        end

        def icdtreekneel3
          # tree_location = icd_code_tree_locations(params[:ajax][:tree_location].to_s)
          # if tree_location.present?
          #   template_id = check_tempalte_id(params[:ajax][:template_id].to_i.to_s)
          #   r_tb_radiology = IcdDiagnosisCode.where(template_id: template_id, tree_level: 'L3', :tree_node.in => ['T'], :tree_location => /^#{tree_location}/i)
          #   respond_to do |format|
          #     format.json { render json: r_tb_radiology }
          #   end
          # end
          # r_tb_radiology = IcdDiagnosisCode.where("tree_node in ('T') and tree_level = 'L3' and SUBSTRING_INDEX(tree_location, '.', 3) = '#{params[:ajax][:tree_location]}' and template_id = #{params[:ajax][:template_id].to_i}")
          r_tb_radiology = IcdDiagnosisCode.where(:template_id => params[:ajax][:template_id].to_i.to_s, :tree_level => 'L3', :tree_node.in => ['T'], :tree_location => /^#{params[:ajax][:tree_location]}/i)
          # r_tb_radiology = IcdDiagnosisCode.where("tree_node in ('T') and tree_level = 'L3' and SUBSTRING_INDEX(tree_location, '.', 3) = '#{params[:ajax][:tree_location]}' and template_id = #{params[:ajax][:template_id].to_i}")
          respond_to do |format|
            format.json { render json: r_tb_radiology }
          end
        end

        def fetchlaboratorytests
          # laboratorytests = LaboratoryInvestigationData.where(investigation_id: (params[:laboratory][:laboratorysetid]).to_i)
          laboratorytests = LaboratoryInvestigationData.where(investigation_id: (params[:laboratory][:laboratorysetid]).to_i)
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
            @inventory_items = Inventory::Item.where(description: /#{Regexp.escape(params[:q])}/i, facility_id: facility_id, is_deleted: false)
            @inventory_items.each do |new_item|
              item = Struct.new(:id, :category, :description, :dispensing_unit, :dosage, :type).new
              item.id = new_item._id
              item.category = new_item.category
              item.description = new_item.description
              item.dispensing_unit = new_item.dispensing_unit if new_item.try(:dispensing_unit)
              item.dosage = new_item.dosage if new_item.try(:dosage)
              item.type = 'NA'
              @items << item
            end

            if @items.empty?
              @new_items = MedicationList.where(name: /#{Regexp.escape(params[:q])}/i)
              @new_items.each do |new_item|
                item = Struct.new(:id, :description, :dosage, :category, :med_type, :type).new
                item.description = new_item.name
                item.dosage = new_item.presentation
                item.category = 'medication'
                item.id = new_item.id
                item.med_type = new_item.med_type
                item.type = 'NA'
                @items << item
              end
            end

          else

            puts "area is #{area}"
            @inventory_item = Inventory::Department::Item::Medication.where(description: /#{Regexp.escape(params[:q])}/i, department_id: 284748001, facility_id: facility_id).limit(20)
            @inventory_item.each do |inv_item|
              item = Struct.new(:id, :description, :dosage, :med_type, :category, :type, :stock).new
              item.description = inv_item.description
              item.dosage = inv_item.dosage
              item.category = 'medication'
              item.type = 'P'
              item.id = inv_item._id
              item.med_type = inv_item.dispensing_unit
              item.stock = inv_item.try(:stock)
              @items << item
            end

            @practice_list = MyPracticeMedicationList.where(name: /#{Regexp.escape(params[:q])}/i, user_id: current_user.id, is_deleted: false).limit(50)
            @practice_list.each do |new_item|
              item = Struct.new(:id, :description, :dosage, :med_type, :category, :type).new
              item.id = new_item._id
              item.description = new_item.name
              item.dosage = ''
              item.med_type = new_item.med_type
              item.category = 'medication'
              item.type = 'M'
              @items << item
            end

            # arr = params[:q].tr('^A-Za-z0-9', ' ').gsub("  "," ").upcase.split(" ")
            # @new_items = CIMSARRAY.select { |set| arr.all? { |t| set[:name].include?(t) } }

            # cims_code_arr = []
            # @new_items.each do |a|
            #  cims_code_arr << a[:cims_id]
            # end

            @cims_medicine = MedicationList.where(name: /#{Regexp.escape(params[:q])}/i).limit(50)
            @cims_medicine.each do |new_item|
              item = Struct.new(:id, :description, :dosage, :med_type, :category, :type).new
              item.id = new_item._id
              item.description = new_item.name
              item.dosage = new_item.presentation
              item.med_type = new_item.med_type
              item.category = 'medication'
              item.type = 'D'
              @items << item
            end
          end
        end

        def get_my_laboratory_set
          set = UsersLaboratoryList.find(params[:q].to_s)
          set = FacilityLaboratoryList.find(params[:q].to_s) if set.blank?
          @lab_list = set.data
          @lab_list = JSON.parse(@lab_list)
          @lab = []
          @lab_list.each do |_key, value|
            @lab.push(value)
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

        def search_procedure
          @common_procedures = CommonProcedure.where(specality_id: params[:specality_id], "$or": [{ name: /#{Regexp.escape(params[:search])}/i }, { code: /#{Regexp.escape(params[:search])}/i }]).limit(50)
          @procedures_array = []

          @common_procedures.each do |procedure|
            procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
            procedure_struc.id = procedure._id
            procedure_struc.name = procedure.name
            procedure_struc.code = procedure.code
            procedure_struc.procedure_type = 'CommonProcedure'
            procedure_struc.procedure_type_label = 'C'
            @procedures_array << procedure_struc
          end

          @custom_common_procedures = CustomCommonProcedure.where(specality_id: params[:specality_id], "$or": [{ name: /#{Regexp.escape(params[:search])}/i }, { code: /#{Regexp.escape(params[:search])}/i }], organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)

          @custom_common_procedures.each do |procedure|
            procedure_struc = Struct.new(:id, :name, :code, :procedure_type, :procedure_type_label).new
            procedure_struc.id = procedure._id
            procedure_struc.name = procedure.name
            procedure_struc.code = procedure.code
            procedure_struc.procedure_type = 'CustomCommonProcedure'
            procedure_struc.procedure_type_label = 'CC'
            @procedures_array << procedure_struc
          end

          @synonym_procedures = SynonymCommonProcedure.where(specality_id: params[:specality_id], name: /#{Regexp.escape(params[:search])}/i, organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)

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

        def get_procedure_details
          @procedure_type = params[:procedure_type]
          @doctors_array = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc).pluck(:fullname, :id).map { |elem| elem.map(&:to_s) }
          @source = (params[:source] if params[:source].present?) || 'opdrecord'
          @id = params[:id]
          @flag = params[:flag]
          @counter = params[:counter]
          @status = params[:status] || 'A'
          @side_id = params[:side_id] || ''
          @procedure_comment = params[:procedure_comment] || ''
          @users_comment = params[:users_comment] || ''
          # @common_procedure = @procedure_type.constantize.find_by(code: params[:code])
          # @common_procedure = check_procedure_type(@procedure_type, params[:code])
          @common_procedure = eval(@procedure_type).find_by(code: params[:code])
          @admission_doctor = (if params[:admission_id].present?
                                 Admission.find_by(id: params[:admission_id]).try(:doctor)
                               end) || current_user.id
          @performed_by_id = params[:performed_by_id]
          @performed_datetime = params[:performed_datetime]
        end

        def append_procedure_details
          @procedure_type = params[:procedure][:procedure_type]
          @source = params[:procedure][:source]
          @procedure = params[:procedure]
          @counter = @procedure[:count]
          # @common_procedure = @procedure_type.constantize.find_by(code: @procedure[:code])
          # @common_procedure = check_procedure_type(@procedure_type, @procedure[:code])
          @common_procedure = eval(@procedure_type).find_by(code: @procedure[:code])
        end

        def add_diagnosis_icd
          # @icd_type = check_icd_type(params[:icd_type].to_s)
          @icd_type = params[:icd_type]
          @source = (params[:source] if params[:source].present?) || 'opdrecord'
          @icdcode = params[:ajax][:icdcode]
          @saperatedicdcode = params[:ajax][:saperatedicdcode]
          @entered_by = params[:ajax][:entered_by]
          @entered_by_id = params[:ajax][:entered_by_id]
          @updated_by = params[:ajax][:updated_by]
          @updated_by_id = params[:ajax][:updated_by_id]
          @diagnosis_comment = params[:ajax][:diagnosis_comment]
          @users_comment = params[:ajax][:users_comment]
          @entry_datetime = params[:ajax][:entry_datetime]
          @entry_time = params[:ajax][:entry_time]
          @updated_datetime = params[:ajax][:updated_datetime]
          @updated_time = params[:ajax][:updated_time]
          @counter = params[:ajax][:counter]
          # @icddiagnosis = @icd_type.constantize.find_by(code: @icdcode)
          @icddiagnosis = eval(@icd_type).find_by(code: @icdcode)
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
          @icd_type = params[:icd_type]
          @icddiagnosis = eval(@icd_type).find_by(code: params[:icdcode])
          @icddiagnosiscode = @icddiagnosis.code.dup
          @icddiagnosiscode = @icddiagnosiscode.insert(3, '.')

          if @icddiagnosis.root == 0
            @parent_diagnosis = @icddiagnosis
          else
            if @icddiagnosis.has_children == false && @icddiagnosis.has_parent == false # some icddiagnosis don't have parent or children diagnosis and 3 digit, with root 1 and no children
              @parent_diagnosis = @icddiagnosis
            else
              parent_code = @icddiagnosis.parentcodename[0][1]
              @parent_diagnosis = eval(@icd_type).find_by(code: parent_code)
              @children_diagnosis = @icddiagnosis
            end
          end

          # Unspecified fracture of second metacarpal bone right hand initial encounter for closed fracture
        end

        def modal_diagnosis_icd
          @doctorsarray = User.where(:facility_ids.in => [current_facility.id], role_ids: 158965000, is_active: true).sort(fullname: :asc).pluck(:fullname, :id).map { |elem| elem.map(&:to_s) }
          @source = (params[:source] if params[:source].present?) || 'opdrecord'
          @icd_type = params[:icd_type]
          @icddiagnosis = eval(@icd_type).find_by(code: params[:ajax].downcase)
          @icddiagnosiscode = @icddiagnosis.code.dup
          @icddiagnosiscode = @icddiagnosiscode.insert(3, '.')

          if @icddiagnosis.root == 0
            @parent_diagnosis = @icddiagnosis
          else
            if @icddiagnosis.has_children == false && @icddiagnosis.has_parent == false # some icddiagnosis don't have parent or children diagnosis and 3 digit, with root 1 and no children
              @parent_diagnosis = @icddiagnosis
            else
              parent_code = @icddiagnosis.parentcodename[0][1]
              @parent_diagnosis = eval(@icd_type).find_by(code: parent_code)
              @children_diagnosis = @icddiagnosis
            end
          end
          # Unspecified fracture of second metacarpal bone right hand initial encounter for closed fracture
        end

        def searchdiagnosis
          arr = params[:q].tr('^A-Za-z0-9', ' ').gsub('  ', ' ').downcase.split(' ')
          @codearray = ICDARRAY.select { |set| arr.all? { |t| set[:fullname].include?(t) } }

          icd_code_arr = []
          @codearray.each do |a|
            icd_code_arr << a[:code]
          end

          @icd_code_array = []
          @icddiagnosis = IcdDiagnosis.where(:code.in => icd_code_arr).limit(50)
          @icddiagnosis.each do |icd_diagnosis|
            icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
            icd.id = icd_diagnosis._id
            icd.originalname = icd_diagnosis.originalname
            icd.fullname = icd_diagnosis.fullname
            icd.code = icd_diagnosis.code
            icd.icd_type = 'IcdDiagnosis'
            icd.icd_type_label = 'I'
            @icd_code_array << icd
          end

          @icddiagnosis = CustomIcdDiagnosis.where("$or": [{ fullname: /#{Regexp.escape(params[:q])}/i }, { code: /#{Regexp.escape(params[:q])}/i }], organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)
          @icddiagnosis.each do |icd_diagnosis|
            icd = Struct.new(:id, :fullname, :code, :is_custom, :icd_type, :icd_type_label, :originalname).new
            icd.id = icd_diagnosis._id
            icd.fullname = icd_diagnosis.fullname
            icd.originalname = icd_diagnosis.originalname
            icd.code = icd_diagnosis.code
            icd.icd_type = icd_diagnosis.icd_type
            icd.icd_type_label = 'C'
            @icd_code_array << icd
          end

          @icddiagnosis = SynonymIcdDiagnosis.where(abbrevated_name: /#{Regexp.escape(params[:q])}/i, organisation_id: current_user.organisation_id, is_deleted: 'false').limit(50)
          @icddiagnosis.each do |icd_diagnosis|
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
            @investigations = RadiologyInvestigationData.where(investigation_id: investigationid.to_i)
            respond_to do |format|
              format.json { render 'get_radiology_attributes' }
            end
          else
            head :ok
          end
        end

        def search_laboratory_list
          @laboratorylist = LaboratoryInvestigationData.where("investigation_name LIKE '%#{params[:q]}%'")
        end

        def show_medicinecontents
          @medicineinformation = MedicationList.find_by(id: params[:medicine_id])
          respond_to do |format|
            format.html { render 'show_medicinecontents', layout: false }
          end
        end

        private

        def check_tempalte_id(template_id)
          if template_id == '244486005'
            '244486005'
          elsif template_id == '28229004'
            '28229004'
          elsif template_id == '252886007'
            '252886007'
          elsif template_id == '10234567'
            '10234567'
          elsif template_id == '244486008'
            '244486008'
          elsif template_id == '252841009'
            '252841009'
          elsif template_id == '406521002'
            '406521002'
          elsif template_id == '244486006'
            '244486006'
          elsif template_id == '244486007'
            '244486007'
          elsif template_id == '244486009'
            '244486009'
          elsif template_id == '395676008'
            '395676008'
          elsif template_id == '244486212'
            '244486212'
          elsif template_id == '60132005'
            '60132005'
          elsif template_id == '5531000179105'
            '5531000179105'
          elsif template_id == '61746007'
            '61746007'
          elsif template_id == '361291001'
            '361291001'
          elsif template_id == '361103004'
            '361103004'
          elsif template_id == '44300000'
            '44300000'
          elsif template_id == '29836001'
            '29836001'
          elsif template_id == '312816002'
            '312816002'
          elsif template_id == '307113009'
            '307113009'
          elsif template_id == '127949000'
            '127949000'
          elsif template_id == '19130008'
            '19130008'
          end
        end
        # EOF check_tempalte_id

        def icd_code_tree_locations(tree_location)
          IcdDiagnosisCode.pluck(:tree_location).uniq.select{|l| l == tree_location}.last
        end
        # EOF icd_code_tree_locations

        def check_icd_type(icd_type)
          if icd_type == 'TranslatedIcdDiagnosis'
            'TranslatedIcdDiagnosis'
          elsif icd_type == 'SynonymIcdDiagnosis'
            'SynonymIcdDiagnosis'
          elsif icd_type == 'CustomIcdDiagnosis'
            'CustomIcdDiagnosis'
          elsif icd_type == 'IcdDiagnosis'
            'IcdDiagnosis'
          elsif icd_type == 'IcdDiagnosisCode'
            'IcdDiagnosisCode'
          elsif icd_type == 'TopOrthoIcdDiagnosis'
            'TopOrthoIcdDiagnosis'
          elsif icd_type == 'TopIcdDiagnosis'
            'TopIcdDiagnosis'
          end
        end
        # EOF check_icd_type

        def check_procedure_type(procedure_type, procedure_code)
          if procedure_type == 'CommonProcedure'
            CommonProcedure.find_by(code: procedure_code)
          elsif procedure_type == 'SynonymCommonProcedure'
            SynonymCommonProcedure.find_by(code: procedure_code)
          elsif procedure_type == 'SynonymCommonProcedure'
            SynonymCommonProcedure.find_by(code: procedure_code)
          elsif procedure_type == 'TranslatedCommonProcedure'
            TranslatedCommonProcedure.find_by(code: procedure_code)
          end
        end
        # EOF check_procedure_type
      end
    end
  end
end
