class SignupJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id, facility_id, user_id)
    organisation = Organisation.find_by(id: organisation_id)
    facility = Facility.find_by(id: facility_id)
    user = User.find_by(id: user_id)

    if organisation.present? && facility.present? && user.present?

      # Welcome and Signup Mail
      UserMailer.welcome_email(organisation, facility, user).deliver_now
      UserMailer.verify_account(user).deliver_now

      # Create OrganisationsSetting
      organisation_setting = OrganisationsSetting.create!(organisation_id: organisation.id, visit_sms_schedule: '0', followup_sms_schedule: '0', long_overdue_sms_schedule: '0', birthday_sms_schedule: '0')

      # Create PrintSetting
      create_print_setting(organisation, facility)

      # InvoiceSetting
      invoice_setting = InvoiceSetting.create!(organisation_id: organisation_id)

      # Increase ReferralCode Use Count by 1
      referral_code = ReferralCode.find_by(code: organisation.referral_code)
      referral_code.inc(use_count: 1) if referral_code.present?

      # Create Organisation ReferralCode
      organisation_referral_code = ReferralCode.create(code: organisation.my_referral_code, new_users_limit: 0, referring_user: organisation.name, free_trial_period: 30, code_expiry_date: Date.current + 2.months, code_release_date: Date.current, use_limit: 10000, organisation_id: organisation.id)

      # # Add Roles # Not needed -> needs check
      # user.add_role :doctor if user.role_ids.include?(158965000)
      # user.add_role :owner if user.role_ids.include?(160943002)
      # user.add_role :admin if user.role_ids.include?(6868009)

      # Create UsersSetting
      users_setting = UsersSetting.create!(organisation_id: user.organisation_id, user_id: user.id, visit_sms_schedule: '0', followup_sms_schedule: '0', long_overdue_sms_schedule: '0')

      # Create AppointmentType old code
      # AppointmentType.create!(
      #   [
      #     { label: "Fresh", duration: 10, background: "#3071a9", is_active: true, is_default: true, user_id: user.id },
      #     { label: "Followup", duration: 5, background: "#274E13", is_active: true, is_default: false, user_id: user.id }
      #   ]
      # )

      # Create UserState
      user_state = UserState.create!(facility_id: facility.id, user_id: user.id)

      # Organisation opd and discharge Feedback templates
      create_organisation_feedback_templates(organisation)

      # Facility Create Job
      FacilityJobs::CreateJob.perform_later(facility_id)
      # Now creating at Organisation Level
      OrganisationJobs::AppointmentTypeJob.perform_later(organisation_id)
      OrganisationJobs::TpaContactsJob.perform_later(organisation_id)
      AppointmentTypeJobs::AppointmentTypeJob.perform_later(facility_id, organisation_id)
      AppointmentTypeJobs::AddOrganisationAppointmentCategoryJob.perform_later(organisation_id)

      # Invoice ServiceMaster's -> ServiceGroups
      create_service_groups = ServiceGroup::CreateService.call(organisation_id, user_id)

      # Create sequences for the organisation
      SequenceManagers::CreateSequenceService.call(organisation_id.to_s)

      # Background Job for UserStatus
      UserStatusJob.perform_later(user_id, organisation_id, user.status, user.quota, user_id)
    end
  end

  private

  def create_organisation_feedback_templates(organisation)
    # opd_feedback_template
    opd_feedback_template = FeedbackSetting.create(organisation_id: organisation.id, set_type: 'opd', opd_feedback_feature: true, discharge_feedback_feature: false)
    opd_questions = opd_feedback_template_attributes
    opd_questions.each_with_index do |opd_question|
      opd_feedback_template.feedback_question_sets.create!(type: opd_question["type"], question_field: opd_question["question_field"])
    end

    # discharge_feedback_template
    discharge_feedback_template = FeedbackSetting.create(organisation_id: organisation.id, set_type: 'discharge', opd_feedback_feature: false, discharge_feedback_feature: true)
    discharge_questions = discharge_feedback_template_attributes
    discharge_questions.each_with_index do |discharge_question|
      discharge_feedback_template.feedback_question_sets.create!(type: discharge_question["type"], question_field: discharge_question["question_field"])
    end
  end

  def opd_feedback_template_attributes
    ([
      { "type" => "accurate_diagnosis", "question_field" => "How easy was it to schedule an appointment with our facility?" },
      { "type" => "bedside_manner", "question_field" => "How long did you wait (beyond your appointment time) to be seen by the provider?" },
      { "type" => "bedside_manner", "question_field" => "How satisfied are you with the cleanliness and appearance of our facility?" },
      { "type" => "promptness", "question_field" => "How would you rate the overall care you received from your provider?" },
      { "type" => "easy_appointment", "question_field" => " How likely are you to recommend our facility to a friend or family member?" }
    ])
  end

  def discharge_feedback_template_attributes
    ([
      { "type" => "accurate_diagnosis", "question_field" => "Were you given information on discharge about the medication you received?" },
      { "type" => "bedside_manner", "question_field" => "Were you given information about what to do if you had any questions or needed assistance after being discharged?" },
      { "type" => "bedside_manner", "question_field" => "Did you use the discharge lounge?" },
      { "type" => "promptness", "question_field" => "Overall how would you rate your discharge experience?" },
      { "type" => "easy_appointment", "question_field" => "How likely are you to recommend our facility to a friend or family member?" }
    ])
  end

  def create_print_setting(organisation, facility)
    department_ids = Department.all.pluck(:id)

    print_setting = PrintSetting.new

    print_setting.organisation_id = organisation.id
    print_setting.type = "default"
    print_setting.name = "Default"
    print_setting.is_editable = false
    print_setting.updated = false
    print_setting.hg_defined = true
    print_setting.department_ids = department_ids
    print_setting.facility_ids = [facility.id]

    letter_head_customisations = organisation.letter_head_customisations

    print_setting.header_height = letter_head_customisations["header_height"]
    print_setting.footer_height = letter_head_customisations["footer_height"]

    print_setting.left_margin = letter_head_customisations["left_margin"]
    print_setting.right_margin = letter_head_customisations["right_margin"]

    print_setting.header_location = letter_head_customisations["header_location"]
    print_setting.header_logo_location = letter_head_customisations["logo_location"]

    print_setting.header = letter_head_customisations["header"]
    print_setting.right = letter_head_customisations["right"]
    print_setting.left = letter_head_customisations["left"]

    print_setting.customised_letter_head = organisation["customised_letter_head"]
    print_setting.customised_footer = organisation["customised_footer"]
    print_setting.footer_text = organisation["footer_text"]
    print_setting.logo = organisation.try(:logo)
    print_setting.save!
  end
end
