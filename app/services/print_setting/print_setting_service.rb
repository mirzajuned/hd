class PrintSettingService
  def initialize(facility_id, user_id, department)
    @facility_setting = FacilitySetting.find_by(facility_id: facility_id)
    @user_id = user_id
    @department = department
    @user = User.find(user_id)
    @organisation = @user.try(:organisation)
    @organisation_setting = @organisation.try(:organisations_setting)
  end

  def dummy_print_setting
    if @facility_setting.nil? and @department == ""
      set_org_print_setting
    elsif @department != "" and @facility_setting.nil?
      @print_setting = @organisation_setting.send(@department.downcase + "_print_setting")
      @logo = @organisation_setting.send(@department.downcase + "_org_logo")
    elsif !@facility_setting.nil? and ["OPD", "IPD"].include? @department
      @print_setting = @facility_setting.send(@department.downcase + "_print_setting")[@user_id.to_s]
      @logo = @user.send(@department.downcase + "_logo")
    elsif !@facility_setting.nil? and ["OPD", "IPD"].exclude? @department
      @print_setting = @facility_setting.send(@department.downcase + "_print_setting")
      @logo = @facility_setting.send(@department.downcase + "_logo")
    end

    return @print_setting, @logo.try(:url)
  end

  def select_print_setting
    # opd ipd doctor wise print setting
    if ["OPD", "IPD"].include? @department and @facility_setting.send(@department.downcase + "_print_setting")[@user_id.to_s] != nil
      opd_ipd_doctors_setting
    # other ipd opd facility wise print setting
    elsif ["OPD", "IPD"].include? @department and @facility_setting.send(@department.downcase + "_print_setting")[@user_id.to_s] == nil
      all_opd_ipd_setting
    else
      other_settings
    end
    return @print_setting, @logo.try(:url)
  end

  private

  def opd_ipd_doctors_setting
    if @facility_setting.send(@department.downcase + "_print_setting")[@user_id.to_s]["updated"]
      @print_setting = @facility_setting.send(@department.downcase + "_print_setting")[@user_id.to_s]
      @logo = @user.send(@department.downcase + "_logo")
    elsif @facility_setting.send("all_print_setting")["updated"]
      @print_setting = @facility_setting.all_print_setting
      @logo = @facility_setting.all_logo
    elsif @organisation_setting.send(@department.downcase + "_print_setting")["updated"]
      set_org_setting_print
    else
      set_org_print_setting
      @logo = @organisation.logo
    end
  end

  def all_opd_ipd_setting
    if @facility_setting.send("all_print_setting")["updated"]
      @print_setting = @facility_setting.all_print_setting
      @logo = @facility_setting.all_logo
    elsif @organisation_setting.send(@department.downcase + "_print_setting")["updated"]
      set_org_setting_print
    else
      set_org_print_setting
      @logo = @organisation.logo
    end
  end

  def other_settings
    if @facility_setting.send(@department.downcase + "_print_setting")["updated"]
      @print_setting = @facility_setting.send(@department.downcase + "_print_setting")
      @logo = @facility_setting.send(@department.downcase + "_logo")
    elsif @facility_setting.send("all_print_setting")["updated"]
      @print_setting = @facility_setting.all_print_setting
      @logo = @facility_setting.all_logo
    elsif @organisation_setting.send(@department.downcase + "_print_setting")["updated"]
      set_org_setting_print
    else
      set_org_print_setting
      @logo = @organisation.logo
    end
  end

  def set_org_setting_print
    @print_setting = @organisation_setting.send(@department.downcase + "_print_setting")
    @logo = @organisation_setting.send(@department.downcase + "_org_logo")
  end

  def set_org_print_setting
    @print_setting = {}
    @print_setting['header_height'] = @organisation.letter_head_customisations["header_height"]
    @print_setting['footer_height'] = @organisation.letter_head_customisations["footer_height"]
    @print_setting['right_margin'] = @organisation.letter_head_customisations["right_margin"]
    @print_setting['left_margin'] = @organisation.letter_head_customisations["left_margin"]
    @print_setting['logo_location'] = @organisation.letter_head_customisations["logo_location"]
    @print_setting['header_location'] = @organisation.letter_head_customisations["header_location"]
    @print_setting['right'] = @organisation.letter_head_customisations["right"]
    @print_setting['left'] = @organisation.letter_head_customisations["left"]
    @print_setting['header'] = @organisation.letter_head_customisations["header"]
    @print_setting['customised_letter_head'] = @organisation.customised_letter_head
    @print_setting['customised_footer'] = @organisation.customised_footer
    @print_setting['footer_text'] = @organisation.footer_text
  end
end
