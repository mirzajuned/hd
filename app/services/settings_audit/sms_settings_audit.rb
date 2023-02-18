class SettingsAudit::SmsSettingsAudit
  def initialize(*args)
    @params = args[0]
    @user_id = args[1]
    @organisation_id = args[2]
    @user = User.find_by(id: @user_id)
  end

  def create_audit
    audit = SettingsAudit.new
    audit.user_id = @user_id
    audit.organisation_id = @organisation_id
    audit.facility_id = @params[:facilityid].present? ? @params[:facilityid] : nil
    audit.level = @params[:level]
    audit.controller_name = @params[:controller]
    audit.action_name = @params[:action]
    audit.user_name = @user.try(:fullname)
    audit.identifier = @params[:identifier]
    audit.save
  end
end
