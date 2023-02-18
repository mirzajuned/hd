class LoggerService
  def integration(params, log_file_name, info)
    logger = Logger.new("#{Rails.root}/log/#{log_file_name}.log")
    logger.debug("============#{Time.current}-------#{info}============")
    logger.debug(params)
  end
end
