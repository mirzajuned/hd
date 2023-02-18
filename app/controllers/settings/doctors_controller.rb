class Settings::DoctorsController < ApplicationController
  before_action :authorize
  respond_to :js, :json, :html
  layout "loggedin"

  def account_settings
    respond_to do |format|
      format.js { render "settings/doctors/account_settings", layout: false }
      format.html {}
    end
  end

  def font_setting
    params.permit(:user_fonts)
    User.find_by(id: current_user.id).users_setting.update_attributes(:font_style => params[:user_fonts][:font_style])
    respond_to do |format|
      format.html { render :nothing => true }
      format.js { render js: "notice = new PNotify({ title: 'Success', text: 'Font saved successfully', type: 'success' }); notice.get().click(function(){ notice.remove() });" }
    end
  end

  def practice_settings
    @queue_settings = TokenSetting.find_by(:user_id => current_user.id)
    @appointment_types = AppointmentType.where(:user_id => current_user.id, :is_active => true)
    @facility_id = current_user.facilities.first.id.to_s
    @current_facility_id = ""
    @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, :facility_id => @facility_id, user_id: current_user.id)
    if @user_settings.nil?
      @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    end
    @organisation = current_user.organisation
    @org_identifier_prefix = @organisation.identifier_prefix
    @user_id = current_user.id.to_s
    TimingsJob.perform_later (@user_id) # Generate schedule for the user

    @user_departments = Department.where(:id.in => current_user.department_ids).map { |dept| { id: dept.id, name: dept.name } }
    respond_to do |format|
      format.js { render "settings/doctors/practice_settings", :layout => false }
      format.html {}
    end
  end

  def save_queue_settings
    # puts params[:walkin_start_from]
    @queue_settings = TokenSetting.find_by(:user_id => current_user.id)

    if @queue_settings == nil
      @queue_settings = TokenSetting.new(walkin_start_from: params[:walkin_start_from])
      @queue_settings.save
    else
      @queue_settings.update(walkin_start_from: params[:walkin_start_from])
    end
  end

  def general_settings_refresh
    @appointment_types = AppointmentType.where(:user_id => current_user.id, :is_active => true)
    @facility_id = current_user.facilities.first.id.to_s
    @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, :facility_id => @facility_id, user_id: current_user.id)
    if @user_settings.nil?
      @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    end
    @organisation = current_user.organisation
    @org_identifier_prefix = @organisation.identifier_prefix
    respond_to do |format|
      format.js {}
    end
  end

  # start==========================general_timings
  def fetch_week_schedule
    @everyday_same_schedule = params[:everyday_same]
    @facility_id = current_user.facilities.first.id
    if params[:facility_id].present?
      @facility_id = params[:facility_id]
    end
    @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, facility_id: @facility_id, user_id: current_user.id)
    if @user_settings.nil?
      @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    end
    respond_to do |format|
      format.js {}
    end
  end

  def save_week_schedule
    # user_id = session[:user_id]
    @organisation = Organisation.find_by(:id => current_user.organisation_id)
    facility_id = params[:facility_id]
    everyday_same_schedule = params[:everyday_same_schedule]
    total_schedule = params[:schedule]
    final_schedule = Hash.new
    count = 0
    timing_flag = "true"
    # Facility Timings should not collide
    User.find_by(id: current_user.id).users_setting.facility_timing.each do |facility| # facility gives each facility of the facility_array
      facility.each do |key, value| # key stores the id of the facility values stores the weekday_timing hash
        if current_user.roles[0].name == "doctor" || current_user.roles[1].try(:name) == "doctor"
          if value == UsersSetting.doctor_setting
            break
          end
        else
          if value == UsersSetting.nurse_setting
            break
          end
        end
        if facility_id.to_s != key.to_s # checking if current facility_id (changing value) is equal to the current facility id of the loop
          total_schedule.each do |saving_index, saving_value| # saving_index gives the gives the day and values gives the timings
            if value[saving_index].present? # for weekday_timing hash if current day is there or not
              if saving_value.present? # for current_day if there are any timings in params i.e one facility should have atleast one timing
                saving_value.each do |i, v| # for current day i gives the slot numbers
                  if value[saving_index][i].present?
                    if value[saving_index][i]["from"] == total_schedule[saving_index][i]["from"] ||
                       value[saving_index][i]["to"] == total_schedule[saving_index][i]["to"] ||
                       Time.zone.parse(total_schedule[saving_index][i]["from"]).between?(Time.zone.parse(value[saving_index][i]["from"]), Time.zone.parse(value[saving_index][i]["to"])) ||
                       Time.zone.parse(total_schedule[saving_index][i]["to"]).between?(Time.zone.parse(value[saving_index][i]["from"]), Time.zone.parse(value[saving_index][i]["to"])) ||
                       Time.zone.parse(value[saving_index][i]["from"]).between?(Time.zone.parse(total_schedule[saving_index][i]["from"]), Time.zone.parse(total_schedule[saving_index][i]["to"])) ||
                       Time.zone.parse(value[saving_index][i]["to"]).between?(Time.zone.parse(total_schedule[saving_index][i]["from"]), Time.zone.parse(total_schedule[saving_index][i]["to"]))
                      timing_flag = "false"
                      flash[:message] = "Your Timings among facilites are colliding"
                      break
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
    if total_schedule.nil?
      timing_flag = false
      flash[:message] = "Fields cannot be empty"
    else
      total_schedule.each do |day_id, each_day_schedule|
        count = 0
        each_day_schedule.each do |index, each_schedule|
          each_schedule['from'] = Time.zone.parse(each_schedule['from']).strftime("%H:%M")
          each_schedule['to'] = Time.zone.parse(each_schedule['to']).strftime("%H:%M")
          if !final_schedule[day_id].present?
            final_schedule[day_id] = Hash.new
          end
          final_schedule[day_id][count] = each_schedule
          count += 1
        end
      end
    end
    flag = nil # defined a nil flag. facility_id
    user_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    if user_setting.nil?
      user_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
      flag = "O" # flag for organisation settings
    end
    weekday_settings = final_schedule
    @facility_timing = []
    User.find_by(id: current_user.id).users_setting.facility_timing.each do |facility_hash|
      facility_hash.each do |facility, hash|
        if facility.to_s == facility_id.to_s
          hash = weekday_settings
        end
        @facility_timing.push(Hash[facility.to_s => hash])
      end
    end

    if flag == "O" && timing_flag == "true" # check the flag for organisation settings
      User.find_by(id: current_user.id).users_setting.update({ :facility_timing => @facility_timing })
    elsif timing_flag == "true"
      User.find_by(id: current_user.id).users_setting.update({ :facility_timing => @facility_timing })
    end
    # unless user_setting
    #   #to complete
    #   weekday_settings = Hash.new
    #   weekday_settings = final_schedule
    #   UsersSetting.create("weekday_setting" => weekday_settings,"everyday_same_timings" => everyday_same_schedule,:org_type => @organisation.type,:org_type_id => @organisation.type_id,:organisation_id => @organisation.id,:facility_id => facility_id,:user_id=>current_user.id)
    # else
    #   weekday_settings = user_setting.weekday_setting
    #   weekday_settings = final_schedule
    #   user_setting.update_attributes(weekday_setting: weekday_settings, everyday_same_timings: everyday_same_schedule)
    # end
    current_user_id = current_user.id.to_s
    TimingsJob.perform_later (current_user_id)
    respond_to do |format|
      format.js { render 'settings/doctors/general_settings_refresh' }
    end
  end
  # end==========================general_timings

  # start==========================printout_customisations
  def save_print_customisations
    params[:letter_head_customisations] = {}
    if params[:customised_letter_head] == 'true'
      params[:letter_head_customisations][:logo_location] = params[:header_logo_location]
      params[:letter_head_customisations][:header_location] = params[:header_location]
      if params[:header_logo_location] == 'left'
        params[:letter_head_customisations][:right] = params[:right_header_text]
      elsif params[:header_logo_location] == 'right'
        params[:letter_head_customisations][:left] = params[:left_header_text]
      elsif params[:header_logo_location] == 'none'
        params[:letter_head_customisations][:left] = params[:left_header_text]
        params[:letter_head_customisations][:right] = params[:right_header_text]
      end
      if params[:header_location] == 'left'
        params[:letter_head_customisations][:header] = params[:header_text]
      elsif params[:header_location] == 'right'
        params[:letter_head_customisations][:header] = params[:header_text]
      elsif params[:header_location] == 'center'
        params[:letter_head_customisations][:header] = params[:header_text]
      end
    end
    params[:letter_head_customisations][:header_height] = params[:letter_head_height]
    params[:letter_head_customisations][:footer_height] = params[:footer_height]
    params[:letter_head_customisations][:left_margin] = params[:left_margin]
    params[:letter_head_customisations][:right_margin] = params[:right_margin]
    # organisation = current_user.organisation

    @organisation = Organisation.find(current_user.organisation_id)

    @organisation.update(org_save_customisations)
  end
  # end==========================printout_customisations

  # start==========================message_customisations
  def sms_followup_modal
    email_sms_modal_common
  end

  def sms_birthday_modal
    email_sms_modal_common
  end

  def sms_appointment_modal
    email_sms_modal_common
  end

  def sms_missed_modal
    email_sms_modal_common
  end

  def sms_discharge_modal
    email_sms_modal_common
  end

  def sms_campaign_modal
    email_sms_modal_common
  end

  def sms_visit_modal
    email_sms_modal_common
  end

  def sms_long_overdue_modal
    email_sms_modal_common
  end

  def email_followup_modal
    email_sms_modal_common
  end

  def email_birthday_modal
    email_sms_modal_common
  end

  def email_appointment_modal
    email_sms_modal_common
  end

  def email_campaign_modal
    email_sms_modal_common
  end

  def email_visit_modal
    email_sms_modal_common
  end

  def email_long_overdue_modal
    email_sms_modal_common
  end
  # end==========================message_customisations

  # below six methods are for active inactive sms setting are getting saved through ajax call
  def followup_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:followup_sms_active_inactive => params[:followup_sms_active_inactive])
    @user_message_setting.update_attributes(:followup_sms_active_inactive => params[:followup_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def birthday_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:birthday_sms_active_inactive => params[:birthday_sms_active_inactive])
    @user_message_setting.update_attributes(:birthday_sms_active_inactive => params[:birthday_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def appointment_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:appointment_sms_active_inactive => params[:appointment_sms_active_inactive])
    @user_message_setting.update_attributes(:appointment_sms_active_inactive => params[:appointment_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def missed_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:missed_sms_active_inactive => params[:missed_sms_active_inactive])
    @user_message_setting.update_attributes(:missed_sms_active_inactive => params[:missed_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def discharge_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:discharge_sms_active_inactive => params[:discharge_sms_active_inactive])
    @user_message_setting.update_attributes(:discharge_sms_active_inactive => params[:discharge_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def campaign_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:campaign_sms_active_inactive => params[:campaign_sms_active_inactive])
    @user_message_setting.update_attributes(:campaign_sms_active_inactive => params[:campaign_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def visit_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:visit_sms_active_inactive => params[:visit_sms_active_inactive])
    @user_message_setting.update_attributes(:visit_sms_active_inactive => params[:visit_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def long_overdue_sms_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:long_overdue_sms_active_inactive => params[:long_overdue_sms_active_inactive])
    @user_message_setting.update_attributes(:long_overdue_sms_active_inactive => params[:long_overdue_sms_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  # next six methods are for SMS settings
  # removed methods from here to sms_settings_controller

  # next six methods are of active inactive email setting are getting saved through ajax call
  def followup_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:followup_email_active_inactive => params[:followup_email_active_inactive])
    @user_message_setting.update_attributes(:followup_email_active_inactive => params[:followup_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def birthday_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:birthday_email_active_inactive => params[:birthday_email_active_inactive])
    @user_message_setting.update_attributes(:birthday_email_active_inactive => params[:birthday_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def appointment_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:appointment_email_active_inactive => params[:appointment_email_active_inactive])
    @user_message_setting.update_attributes(:appointment_email_active_inactive => params[:appointment_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def campaign_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:campaign_email_active_inactive => params[:campaign_email_active_inactive])
    @user_message_setting.update_attributes(:campaign_email_active_inactive => params[:campaign_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def visit_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:visit_email_active_inactive => params[:visit_email_active_inactive])
    @user_message_setting.update_attributes(:visit_email_active_inactive => params[:visit_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  def long_overdue_email_setting_save
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(:long_overdue_email_active_inactive => params[:long_overdue_email_active_inactive])
    @user_message_setting.update_attributes(:long_overdue_email_active_inactive => params[:long_overdue_email_active_inactive])
    respond_to do |format|
      format.js { head :ok, layout: false }
    end
  end

  # next six methods are for Email settings
  def followup_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(followup_email_setting_params)
    @user_message_setting.update_attributes(followup_email_setting_params)
    email_setting_refresh
  end

  def birthday_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(birthday_email_setting_params)
    @user_message_setting.update_attributes(birthday_email_setting_params)
    email_setting_refresh
  end

  def appointment_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(appointment_email_setting_params)
    @user_message_setting.update_attributes(appointment_email_setting_params)
    email_setting_refresh
  end

  def campaign_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(campaign_email_setting_params)
    @user_message_setting.update_attributes(campaign_email_setting_params)
    email_setting_refresh
  end

  def visit_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(visit_email_setting_params)
    @user_message_setting.update_attributes(visit_email_setting_params)
    email_setting_refresh
  end

  def long_overdue_email_setting
    @org_message_setting = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    @user_message_setting = UsersSetting.find_by(organisation_id: current_user.organisation_id, user_id: current_user.id)
    @org_message_setting.update_attributes(long_overdue_email_setting_params)
    @user_message_setting.update_attributes(long_overdue_email_setting_params)
    email_setting_refresh
  end

  def preview_printout_customization
    @preview_type = "account_setting"
    @organisation = current_user.organisation
    respond_to do |format|
      format.js {}
    end
  end
end

private

def org_save_customisations
  params.permit(:logo, :customised_letter_head, :customised_footer, :footer_text, letter_head_customisations: [:header_height, :footer_height, :left_margin, :right_margin, :logo_location, :header_location, :left, :right, :header])
end

def email_sms_modal_common
  if params[:facility_id]
    @facility_id = params[:facility_id]
    @facility_setting = Facility.find(@facility_id).facility_setting
    @setting_source = @facility_setting
  else
    @facility_id = current_user.facilities.first.id.to_s
    @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, :facility_id => @facility_id, user_id: current_user.id)
    if @user_settings.nil?
      @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
    end
    @setting_source = @user_settings
  end
  @organisation = current_user.organisation

  respond_to do |format|
    format.js {}
  end
end

def email_setting_refresh
  @facility_id = current_user.facilities.first.id.to_s
  @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, :facility_id => @facility_id, user_id: current_user.id)
  if @user_settings.nil?
    @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end
  respond_to do |format|
    format.js { render 'refresh_email_setting' }
  end
end

def sms_setting_refresh
  @facility_id = current_user.facilities.first.id.to_s
  @user_settings = UsersSetting.find_by(organisation_id: current_user.organisation_id, :facility_id => @facility_id, user_id: current_user.id)
  if @user_settings.nil?
    @user_settings = OrganisationsSetting.find_by(organisation_id: current_user.organisation_id)
  end
  respond_to do |format|
    format.js { render 'refresh_sms_setting' }
  end
end

def refresh_facility_sms_setting_page
  respond_to do |format|
    format.js { render 'refresh_facility_sms_setting_page' }
  end
end

def followup_email_setting_params
  params.permit(:followup_email_subject, :followup_email_body, :followup_email_time, :followup_email_schedule)
end

def birthday_email_setting_params
  params.permit(:birthday_email_subject, :birthday_email_body, :birthday_email_time, :birthday_email_schedule)
end

def appointment_email_setting_params
  params.permit(:appointment_email_subject, :appointment_email_body, :appointment_email_time, :appointment_email_schedule)
end

def campaign_email_setting_params
  params.permit(:campaign_email_subject, :campaign_email_body, :campaign_email_time, :campaign_email_schedule)
end

def visit_email_setting_params
  params.permit(:visit_email_subject, :visit_email_body, :visit_email_time, :visit_email_schedule)
end

def long_overdue_email_setting_params
  params.permit(:long_overdue_email_subject, :long_overdue_email_body, :long_overdue_email_time, :long_overdue_email_schedule)
end
