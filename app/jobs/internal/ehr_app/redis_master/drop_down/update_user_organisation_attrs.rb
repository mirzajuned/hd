class Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs < ActiveJob::Base

  def perform(mandatory, optional = {}, others = {})
    Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: entering")

    Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: mandatory fields :: #{mandatory}")
		Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: optional fields  :: #{optional}")
		Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: others fields  :: #{others}")

    organisation_id = "#{mandatory['organisation_id'].to_s}"
    Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: organisation_id var  :: #{organisation_id}")
    User::Update.update_dropdown_attributes_in_redis_master(organisation_id)

    Rails.logger.info("Internal::EhrApp::RedisMaster::DropDown::UpdateUserOrganisationAttrs :: perform method :: existing")
  end

end
