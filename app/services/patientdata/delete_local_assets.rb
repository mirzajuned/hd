class Patientdata::DeleteLocalAssets

  def self.call(logger_file)
    tmp_folder = Rails.root.to_s + '/public/uploads/tmp/'
    FileUtils.cd(tmp_folder)
    Dir.entries(tmp_folder).each do |file|
      FileUtils.rm_rf(file) if File.stat(file).ctime < (Time.now - 15.minutes) && ['.', '..'].exclude?(file.to_s)
    end
  end
end
