class ProcessInBackgroundJob < ActiveJob::Base

  def perform(object_config, mandatory, optional = {}, others = {})
    Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: object_config fields :: #{object_config}")
    Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: mandatory fields :: #{mandatory}")
    Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: optional fields :: #{optional}")
    Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: others fields :: #{others}")
    organisation_id = "#{mandatory['organisation_id']}"
    Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: organisation_id field :: #{organisation_id}")

    # 1. Internal Jobs
    if Global.sidekiq.jobs_to_envs_internal_config.is_job_run_enabled_for_env
      if Global.sidekiq.jobs_to_envs_internal_config.is_job_enabled_for_all_orgs
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: if block :: is_job_enabled_for_all_orgs true")
        process_jobs("internal", object_config, mandatory, optional, others)
      elsif Global.sidekiq.jobs_to_envs_internal_config.is_job_enabled_for_all_orgs.eql?(false) & Global.sidekiq.jobs_to_envs_internal_config.whitelisted_organisation_ids.include?(organisation_id)
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: is_job_enabled_for_all_orgs false")
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: whitelisted_organisation_ids :: organisation_id exists in whitelisting :: #{organisation_id}")
        process_jobs("internal", object_config, mandatory, optional, others)
      end
    end # end of Internal if

    # 2. Interapp Jobs
    # Commented for future
    # if Global.sidekiq.jobs_to_envs_interapp_config.is_api_call_enabled_for_env
    #   if Global.sidekiq.jobs_to_envs_interapp_config.is_api_call_enabled_for_all_orgs
    #     Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: if block :: is_api_call_enabled_for_all_orgs true")
    #     process_jobs("interapp", object_config, mandatory, optional, others)
    #   elsif Global.sidekiq.jobs_to_envs_interapp_config.is_api_call_enabled_for_all_orgs.eql?(false) & Global.sidekiq.jobs_to_envs_interapp_config.whitelisted_organisation_ids.include?(organisation_id)
    #     Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: is_api_call_enabled_for_all_orgs false")
    #     Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: whitelisted_organisation_ids :: organisation_id exists in whitelisting :: #{organisation_id}")
    #     process_jobs("interapp", object_config, mandatory, optional, others)
    #   end
    # end # end of Interapp if

    # 3. External Jobs means API calls to apis hosted by our partners or other app vendors such as Sankara, Dr Agarwals, etc...
    if Global.sidekiq.jobs_to_envs_external_config.is_api_call_enabled_for_env
      if Global.sidekiq.jobs_to_envs_external_config.is_api_call_enabled_for_all_orgs
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: if block :: is_api_call_enabled_for_all_orgs true")
        process_jobs("external", object_config, mandatory, optional, others)
      elsif Global.sidekiq.jobs_to_envs_external_config.is_api_call_enabled_for_all_orgs.eql?(false) & Global.sidekiq.jobs_to_envs_external_config.whitelisted_organisation_ids.include?(organisation_id)
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: is_api_call_enabled_for_all_orgs false")
        Rails.logger.info("Inside ProcessInBackgroundJob :: perform method :: elsif block :: whitelisted_organisation_ids :: organisation_id exists in whitelisting :: #{organisation_id}")
        process_jobs("external", object_config, mandatory, optional, others)
      end
    end # end of External if

  end # end of perform method

  private

    def process_jobs(job_type, object_config, mandatory, optional, others)
      Rails.logger.info("Inside ProcessInBackgroundJob :: process_jobs method :: job_type var :: #{job_type}")
      class_method_name_var = "#{object_config['class_name']}_#{object_config['method_name']}"
      Rails.logger.info("Inside ProcessInBackgroundJob :: process_jobs method :: class_method_name_var var :: #{class_method_name_var}")
      if Global.sidekiq.send("jobs_#{job_type}").key?("#{class_method_name_var}")
        queues = ["urgent", "delayed"]
        queues&.each do |queue_name|
          sidekiq_bg_jobs_to_process = []
          sidekiq_bg_jobs_to_process = Global.sidekiq.send("jobs_#{job_type}")["#{class_method_name_var}"]["jobs"]["#{queue_name}"]
          Rails.logger.info("Inside ProcessInBackgroundJob :: process_jobs method :: queues.each lopping :: queue_name var  :: #{queue_name}")
          Rails.logger.info("Inside ProcessInBackgroundJob :: process_jobs method :: queues.each lopping :: sidekiq_bg_jobs_to_process array :: #{sidekiq_bg_jobs_to_process}")
          sidekiq_bg_jobs_to_process&.each do |job_id|
            Rails.logger.info("Inside ProcessInBackgroundJob :: process_jobs method :: sidekiq_bg_jobs_to_process.each lopping :: job_type, queue_name, & job_id vars :: #{job_type} :: #{queue_name} :: #{job_id}")
            call_sidekiq(job_type, queue_name, job_id, object_config, mandatory, optional, others)
          end
        end
      end
    end

    def call_sidekiq(job_type, queue_name, job_id, object_config, mandatory, optional, others)
      sidekiq_job = Global.sidekiq.jobs["#{job_id}"]
      job_customer = "#{sidekiq_job['job_customer']}"
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: job_type var :: #{job_type}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: job_id var :: #{job_id}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: queue_name var :: #{queue_name}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: sidekiq_job var :: #{sidekiq_job}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: job_customer var :: #{job_customer}")
      external_api = ""
      wait_in_mins = 1
      if ["interapp", "external"].include?(job_type)
        external_api = Global.sidekiq.jobs_api_mapping["#{job_id}"]["api"]
      end
      if queue_name.eql?("urgent")
        wait_in_mins = rand(Global.sidekiq.job_config["#{queue_name}_queue_wait_in_mins"].to_i)
      elsif queue_name.eql?("delayed")
        wait_in_mins = rand(Global.sidekiq.job_config["#{queue_name}_queue_wait_in_mins_min"].to_i..Global.sidekiq.job_config["#{queue_name}_queue_wait_in_mins_max"].to_i)
      end
      mandatory["external_api"] = external_api
      mandatory["job_customer"] = job_customer
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: external_api var :: #{external_api}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: wait_in_mins var :: #{wait_in_mins}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: mandatory var :: #{mandatory}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: optional var :: #{optional}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: others var :: #{others}")
      Rails.logger.info("Inside ProcessInBackgroundJob :: call_sidekiq method :: BEFORE CALL TO perform_later")
      "#{sidekiq_job['class_name']}".constantize.set(queue: queue_name, wait_until: wait_in_mins).perform_later(mandatory, optional, others)
    end

end # end of class

# Sample code for future if need be, it is not required though.
# sidekiq_bg_jobs_to_process&.each do |job|
#   "#{job['class_name']}".constantize.set(queue: job["queue_as"].to_sym, wait_until: job["wait_in_mins"]).perform_later(mandatory, optional, others)
# end
