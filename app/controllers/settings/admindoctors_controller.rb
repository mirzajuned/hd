class Settings::AdmindoctorsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def account_settings
    respond_to do |format|
      format.js { render "settings/admindoctors/account_settings", layout: false }
      format.html {}
    end
  end

  def print_settings
    @organisation = current_user.organisation
    @current_user_facility_settings = current_user_facility_settings
    if current_user.role_ids.include? 158965000
      @facility_setting = FacilitySetting.find_by(facility_id: current_facility.id)
      if @facility_setting.opd_print_setting[current_user.id.to_s].nil? || @facility_setting.opd_print_setting[current_user.id.to_s].nil?
        Facility.find_by(id: current_facility.id).update!
      end
    end
    respond_to do |format|
      format.js { render "settings/admindoctors/print_settings", layout: false }
      format.html {}
    end
  end

  def reload_print_setting
    @department = check_departments('all', params[:department])
    @facility_setting_id = params[:facility_setting_id]
    @user = User.find_by(id: current_user.id)
    # filter for all department, all facility
    if @facility_setting_id == '' and @department == "All"
      @organisation = current_user.organisation

      @all_flag = 1
      respond_to do |format|
        format.js { render 'reload_organisation_setting' }
      end
    end

    # filter individual all facility, individual department
    if @department != "All" and @facility_setting_id == ''
      @org_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation.id)
      @print_setting = @org_settings.send(@department.downcase + "_print_setting")
      set_org_logo_input_output(@org_settings)
      
      respond_to do |format|
        format.js { render 'reload_facility_setting' }
      end
    end

    # filter for sepcific facility specific department
    if @facility_setting_id != ''
      @facility_setting = FacilitySetting.find(@facility_setting_id)
      @facility_name = @facility_setting.facility.name
      if ["OPD", "IPD"].include? @department
        @print_setting = @facility_setting.send(@department.downcase + "_print_setting")
        @print_setting
        set_user_logo_input_output(@user)
      else
        @print_setting = @facility_setting.send(@department.downcase + "_print_setting")
        set_fac_logo_input_output(@facility_setting)
      end
    end
  end

  def save_print_setting
    @department = check_departments('all', params[:department])
    @facility_setting_id = params[:facility_setting_id]
    @org_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation.id)
    @user = User.find_by(id: current_user.id)
    if ['OPD', 'IPD', 'Invoice', 'Pharmacy', 'Optical', 'Laboratory', 'Radiology', 'Ophthalmology'].include?(@department)
      if @department != "All" and @facility_setting_id == ''
        @print_setting = @org_settings.send(@department.downcase + '_print_setting')
        set_setting_params
        # organisation = current_user.organisation
        @org_settings.update(save_org_setting_print_customization)
        @logo = @org_settings.send(@department.downcase + '_org_logo')
      end
    end
    # for facility and department specific
    if @facility_setting_id != ''
      @facility_setting = FacilitySetting.find(@facility_setting_id)
      if ["OPD", "IPD"].include? @department
        @print_setting = @facility_setting.send(@department.downcase + '_print_setting')[current_user.id.to_s]
        set_setting_params
        @user.update(update_user_dept_logo)
        @facility_setting.update(update_user_dept)
        @logo = @user.send(@department.downcase + '_logo')
      elsif ['Invoice', 'Pharmacy', 'Optical', 'Laboratory', 'Radiology', 'Ophthalmology'].include?(@department)
        @print_setting = @facility_setting.send(@department.downcase + '_print_setting')
        set_setting_params
        @facility_setting.update(save_fac_setting_print_customization)
        @logo = @facility_setting.send(@department.downcase + '_logo')
      end
    end

    respond_to do |format|
      format.js {}
    end
  end

  def preview_print
    @speciality_folder_name = "ophthalmology"
    @department = check_departments('all', params[:department])
    @facility_setting_id = params[:facility_setting_id]
    @facility_setting = FacilitySetting.find(@facility_setting_id)
    @org_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation.id)
    @user = User.find_by(id: current_user.id)
    setting_service = PrintSettingService.new(@facility_setting.try(:facility_id).to_s, current_user.id.to_s, @department)
    @print_settings = setting_service.dummy_print_setting
    @logo = @print_settings[1]

    respond_to do |format|
      format.pdf { render :template => "settings/admindoctors/print_preview", :pdf => "Dummy-Print", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 0, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { left: @print_settings[0]['left_margin'].to_f * 10, right: @print_settings[0]['right_margin'].to_f * 10, :top => @print_settings[0]['header_height'].to_f * 10, :bottom => @print_settings[0]['footer_height'].to_f * 10 } }
    end
  end

  private

  def update_user_dept_logo
    params.permit(@department.downcase + '_logo')
  end

  def update_user_dept
    params.permit(@print_setting)
  end

  def set_org_logo_input_output(print_setting)
    @logo_input_field = @department.downcase + "_org_logo"
    @logo = print_setting.send(@department.downcase + "_org_logo")
  end

  def set_user_logo_input_output(user)
    @logo_input_field = @department.downcase + "_logo"
    @logo = user.send(@logo_input_field)
  end

  def set_fac_logo_input_output(print_setting)
    @logo_input_field = @department.downcase + "_logo"
    @logo = print_setting.send(@department.downcase + "_logo")
  end

  def save_org_setting_print_customization
    params.permit(@department.downcase + '_org_logo', @print_setting, @updated)
  end

  def save_fac_setting_print_customization
    params.permit(@department.downcase + '_logo', @print_setting)
  end

  def set_setting_params
    if params[:customised_letter_head] == 'true'
      @print_setting[:customised_letter_head] = true
      @print_setting[:updated] = ActiveModel::Type::Boolean.new.cast(params[:updated].to_s.downcase)
      @print_setting[:logo_location] = params[:header_logo_location]
      @print_setting[:header_location] = params[:header_location]
      if params[:header_logo_location] == 'left'
        @print_setting[:right] = params[:right_header_text]
      elsif params[:header_logo_location] == 'right'
        @print_setting[:left] = params[:left_header_text]
      elsif params[:header_logo_location] == 'none'
        @print_setting[:left] = params[:left_header_text]
        @print_setting[:right] = params[:right_header_text]
      end
      if params[:header_location] == 'left'
        @print_setting[:header] = params[:header_text]
      elsif params[:header_location] == 'right'
        @print_setting[:header] = params[:header_text]
      elsif params[:header_location] == 'center'
        @print_setting[:header] = params[:header_text]
      end
    end
    @print_setting[:header_height] = params[:letter_head_height]
    @print_setting[:footer_height] = params[:footer_height]
    @print_setting[:left_margin] = params[:left_margin]
    @print_setting[:right_margin] = params[:right_margin]
    @print_setting[:customised_footer] = ActiveModel::Type::Boolean.new.cast(params[:customised_footer].to_s.downcase)
    @print_setting[:footer_text] = params[:footer_text]
  end

  def check_departments(check_type, department)
    department = ''
    all = ['All', 'OPD', 'IPD', 'Invoice', 'Pharmacy', 'Optical', 'Laboratory', 'Radiology', 'Ophthalmology']
    if check_type == 'all'
      department = all.select{|i| i == department}.first
    elsif check_type == 'opdipd'
      department = all[1,2].select{|i| i == department}.first
    elsif check_type == 'except_opdipd'
      department = all[3..-1].select{|i| i == department}.first
    end
    department
  end
  # EOF check_departments
end
