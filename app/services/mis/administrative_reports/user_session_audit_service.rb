module Mis::AdministrativeReports
  class UserSessionAuditService
    class << self
      def log(params)
        params = JSON.parse(params).with_indifferent_access
        user = User.find_by(id: params[:user_id])
        params[:organisation_id] = user.try(:organisation).try(:id)
        params[:facility_name] = Facility.find_by(id: params[:facility_id]).try(:name)
        params[:user_role] = user.try(:primary_role).try(:capitalize)
        params[:user_name] = user.try(:username)
        params[:user_full_name] = user.try(:fullname).try(:capitalize)
        params[:device_name] = extract_device_name(params[:user_agent]).try(:capitalize)
        params[:device_type] = extract_device_type(params[:user_agent]).try(:capitalize)
        UserSessionAudit.create(params)
      end

      def extract_device_name(user_agent)
        user_agent.split('AppleWebKit')[0].split('(')[1].delete(')').delete(';')
      end

      def extract_device_type(user_agent)
        return 'tablet' if user_agent.match?(/(tablet|ipad)|(android(?!.*mobile))/i)

        return 'mobile' if user_agent.match?(/Mobile/)

        'desktop'
      end
    end
  end
end
