module Mis::RevenueReports
  class UpdateSubSpecialitiesService
    class << self
      def call(organisation_id, master_id, master_name, pricing_masters, mis_logger=nil)
        mis_logger = mis_logger || Logger.new("#{Rails.root}/log/mis_logger.log")
        if master_name == 'service_master'
          master = ServiceMaster.find_by(id: master_id)
          finance_stats = Finance::StatisticService.where(organisation_id: organisation_id, :service_id.in => pricing_masters)
        elsif master_name == 'surgery_package'
          finance_stats = Finance::StatisticPackage.where(organisation_id: organisation_id, surgery_package_id: master_id)
        end

        return if finance_stats.count == 0
        specialty_id = master.specialty_id
        specialty_name = Specialty.find_by(id: specialty_id).try(:name)
        sub_specialty_id = master.sub_specialty_id
        sub_specialty_name = SubSpecialty.find_by(id: sub_specialty_id).try(:name)
        finance_stats.update_all(
          specialty_id: specialty_id, specialty_name: specialty_name,
          sub_specialty_id: sub_specialty_id, sub_specialty_name: sub_specialty_name
        )
      # rescue StandardError => e
      #   mis_logger.error(" === error in UpdateSubSpecialitiesService :: #{e.inspect}")
      end
    end
  end
end
