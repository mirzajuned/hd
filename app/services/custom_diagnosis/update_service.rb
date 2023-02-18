class CustomDiagnosis::UpdateService
  def self.call(params, icd_id)
    @icd_original_name = params[:originalname]
    @icd_abbrevated_name = @icd_original_name.gsub(',', ' ').gsub(' ', '')
    @custom_icd_diagnosis = CustomIcdDiagnosis.find_by(id: icd_id)
    @parent_icd_code = @custom_icd_diagnosis.code
    @parent_icd_code_size = @parent_icd_code.to_s.size
    childrenfullinfo = []
    childrencodename = []
    @custom_icd_diagnosis.update_attributes(fullname: @icd_abbrevated_name, abbrevated_name: @icd_abbrevated_name, originalname: @icd_original_name)

    if @custom_icd_diagnosis.has_children == true
      values = [['1', 'right'], ['2', 'left'], ['3', 'bilateral'], ['4', 'unspecified']]
      values.each do |value|
        parentcodename = []
        parentfullinfo = []
        originatingcodes = []

        @children_code = @parent_icd_code.to_s + value[0]
        childrencodesize = @children_code.size
        @children_icd_diagnosis = CustomIcdDiagnosis.find_by(code: @children_code)
        @children_original_name = @icd_original_name + ", " + value[1]
        @children_full_name = @children_original_name.gsub(',', ' ').gsub(' ', '')
        @childrenshortname = value[1]

        # updating children icd arrays
        originatingcodes << [@icd_abbrevated_name, @parent_icd_code.to_s]
        parentcodename << [@icd_abbrevated_name, @parent_icd_code.to_s]
        parentfullinfo << { @parent_icd_code_size => [@parent_icd_code.to_s, @icd_abbrevated_name, @icd_abbrevated_name, @icd_abbrevated_name] }

        @children_icd_diagnosis.update_attributes(originatingcodes: originatingcodes, parentcodename: parentcodename, parentfullinfo: parentfullinfo, fullname: @children_full_name, abbrevated_name: @children_full_name, originalname: @children_original_name)

        childrenfullinfo << { childrencodesize => [@children_code.to_s, @children_full_name, @children_full_name, @childrenshortname] }
        childrencodename << [@childrenshortname, @children_code.to_s]
      end
      # updating parent icd array
      @custom_icd_diagnosis.update_attributes(childrenfullinfo: childrenfullinfo, childrencodename: childrencodename)
    end
  end
end
