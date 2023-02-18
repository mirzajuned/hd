module Mis::AdministrativeReports
  class OrganisationNotificationService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []
        if xlsx?
          @data_array << ['Created Date', 'Created By', 'Notification Start Date', 'Notification End Date',
                          'Facilities', 'Roles', 'Active', 'Subject', 'Message', 'Attachments']
        end

        @notifications = filtered_notifications
        @facilities = find_uniq_facilities
        @roles = find_uniq_roles

        notification_display_limit.each do |notification|
          data_array = create_data_array(notification)

          @data_array << data_array
        end

        [@data_array, @notifications.size]
      end

      private

      def xlsx?
        @request == 'xlsx'
      end

      def notification_display_limit
        return @notifications if xlsx?

        @notifications.skip(@mis_params[:iDisplayStart]).limit(@mis_params[:iDisplayLength])
      end

      def filtered_notifications
        organisation_id = @mis_params[:organisation_id]
        facility_id = @mis_params[:facility_id]
        role_id = @mis_params[:role_id]

        time_frame = @mis_params[:start_date].beginning_of_day..@mis_params[:end_date].end_of_day

        notifications = OrganisationNotification
                        .includes(:user)
                        .where(organisation_id: organisation_id, deleted: false, created_at: time_frame)

        if @mis_params[:facility_id].present?
          notifications = notifications.where('$or': [{ all_facilities: true }, { facility_ids: facility_id }])
        end

        if @mis_params[:role_id].present? && @mis_params[:role_id] != 'All'
          notifications = notifications.where('$or': [{ all_roles: true }, { role_ids: role_id }])
        end

        notifications
      end

      def find_uniq_facilities
        all_facility_ids = @notifications.pluck(:facility_ids).flatten.uniq

        Facility.where(:id.in => all_facility_ids).map { |facility| { id: facility.id.to_s, name: facility.name } }
      end

      def find_uniq_roles
        all_role_ids = @notifications.pluck(:role_ids).flatten.uniq

        Role.where(:id.in => all_role_ids.map(&:to_i)).map { |role| { id: role.id.to_s, label: role.label } }
      end

      def create_data_array(notification)
        [notification.created_at.to_date.to_s(:standard),
         notification.user.fullname,
         notification.start_date.to_s(:standard),
         notification.end_date.to_s(:standard),
         facilities(notification),
         roles(notification),
         notification.active ? 'Yes' : 'No',
         notification.title,
         formatted_body(notification),
         web_links(notification).join(separator)]
      end

      def formatted_body(notification)
        xlsx? ? notification.body.gsub(/<[^>]+>/, ' ').gsub('&nbsp;', '').strip : notification.body
      end

      def facilities(notification)
        return 'Organisation Wide' if notification.all_facilities

        @facilities.select { |facility| notification.facility_ids.include?(facility[:id].to_s) }
                   .pluck(:name).join(separator)
      end

      def roles(notification)
        return 'All Roles' if notification.all_roles

        @roles.select { |role| notification.role_ids.include?(role[:id].to_s) }.pluck(:label).join(separator)
      end

      def web_links(notification)
        notification.web_links.each_with_object([]) do |web_link, array|
          link_text = web_link[:link_text].present? ? web_link[:link_text] : web_link[:link]
          array << if xlsx?
                     "#{"#{web_link[:link_text]} -" if web_link[:link_text].present?} #{web_link[:link]}"
                   else
                     "<a href='#{web_link[:link]}' target='_blank'>#{link_text}</a>"
                   end
        end
      end

      def separator
        xlsx? ? ' | ' : '<br>'
      end
    end
  end
end
