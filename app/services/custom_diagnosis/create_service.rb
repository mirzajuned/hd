class CustomDiagnosis::CreateService
  def self.call(params, current_user)
    new_parent_icd_params(params, current_user)
    @icd_diagnosis = CustomIcdDiagnosis.new(icd_diagnosis_params(params))
    @icd_diagnosis.save

    return @icd_diagnosis
  end

  private

  def self.new_parent_icd_params(params, current_user)
    @icd_name = params[:fullname]
    icd_counter = current_user.organisation.diagnosis_counter
    identifier_prefix = current_user.organisation.identifier_prefix.downcase.to_s + 'icd'
    code = CommonHelper::get_common_icd_identifier(current_user)
    codelength = code.to_s.size

    if params[:children_has_laterality] == 'true'

      laterality_filter = []
      childrencodename = []
      childrenfullinfo = []

      values = [['1', 'right'], ['2', 'left'], ['3', 'bilateral'], ['4', 'unspecified']]
      values.each.with_index do |value, i|
        childrencode_suffix = icd_counter.to_s + value[0]
        childrencode = identifier_prefix + childrencode_suffix
        childrenfullname = @icd_name + ", " + value[1]

        # creating children diagnosis if laterality added
        creating_children_diagnosis(params, value, @icd_name, code, codelength, current_user, childrencode, childrenfullname, childrencode_suffix)

        childrenshortname = value[1]
        childrenfullname = @icd_name + ", " + value[1]
        childrencodesize = childrencode.size
        laterality_filter << value[1]
        childrencodename << [childrenshortname, childrencode.to_s]
        childrenfullinfo << { childrencodesize => [childrencode.to_s, childrenfullname, childrenfullname, childrenshortname] }

        params[:childrencodename] = childrencodename
        params[:childrenfullinfo] = childrenfullinfo
        params[:laterality_filter] = laterality_filter
        params[:has_children] = true
        params[:has_laterality] = false
        params[:children_has_laterality] = true
        params[:has_parent] = false
      end
    else
      params[:has_children] = false
      params[:childrencodename] = []
      params[:childrenfullinfo] = []
      params[:laterality_filter] = []
    end

    params[:originalname] = params[:shortname] = @icd_name
    params[:root] = 0
    params[:fullname] = @icd_name.gsub(',', ' ').gsub(' ', '')
    params[:abbrevated_name] = @icd_name.gsub(',', ' ').gsub(' ', '')
    params[:code] = params[:shortcode] = code
    params[:separatedcode] = current_user.organisation.identifier_prefix.downcase.to_s + '|icd|' + icd_counter.to_s
    params[:codelength] = codelength
    params[:originatingcodes] = []
    params[:parentcodename] = []
    params[:parentfullinfo] = []
  end

  def self.creating_children_diagnosis(params, value, icd_name, parent_icd_code, icd_code_length, current_user, childrencode, childrenfullname, childrencode_suffix)
    originatingcodes = []
    parentcodename = []
    parentfullinfo = []

    childrencodesize = childrencode.to_s.size
    originatingcodes << [icd_name, parent_icd_code]
    parentcodename << [icd_name, parent_icd_code]
    parentfullinfo << { icd_code_length => [parent_icd_code, icd_name, icd_name, icd_name] }

    params[:codelength] = childrencodesize
    params[:abbrevated_name] = params[:fullname] = childrenfullname.gsub(',', ' ').gsub(' ', '')
    params[:originalname] = childrenfullname
    params[:code] = childrencode
    params[:originatingcodes] = originatingcodes
    params[:parentfullinfo] = parentfullinfo
    params[:parentcodename] = parentcodename
    params[:root] = 1
    params[:has_parent] = true
    params[:childrencodename] = []
    params[:childrenfullinfo] = []
    params[:laterality_filter] = []
    params[:has_children] = false
    params[:children_has_laterality] = false
    params[:shortcode] = value[0]
    params[:shortname] = value[1]
    params[:has_laterality] = true
    params[:shortname] = childrenfullname
    params[:laterality_position] = ""
    params[:separatedcode] = current_user.organisation.identifier_prefix.downcase.to_s + '|icd|' + childrencode_suffix.to_s

    @icd_diagnosis_children = CustomIcdDiagnosis.new(icd_diagnosis_params(params))
    @icd_diagnosis_children.save
  end

  def self.icd_diagnosis_params(params)
    params.permit!
  end
end
