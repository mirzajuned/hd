# 3   Metrics/AbcSize
# 3   Metrics/CyclomaticComplexity
# 3   Metrics/MethodLength
# 3   Metrics/PerceivedComplexity
# 1   Metrics/BlockLength
# 1   Metrics/ClassLength
# --
# 14  Total
module Mis::RevenueReports
  class BillsByServicesService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        # chceck_specialties(@mis_params[:facility_id])
        @request = request
        @data_array = []
        @data_array << Mis::Constants::ReportSheetFilters.revenue_filters(@mis_params) if @request == 'xls'

        services = Finance::StatisticService.collection.aggregate(statistic_query).to_a || {}
        @services = if @request == 'xls'
            services || []
          else
            services[0][:data] || []
          end
        total_records = if services.present? && @request == 'xls'
            services[0][:total] || 0
          elsif services.present? && services[0][:metadata].present?
            services[0][:metadata][0][:total]
          else
            0
          end
        service_data
        [@data_array, total_records]
      end
      # EOF call

      private

      def statistic_query
        # Finance::StatisticData Query
        Mis::QueryBuilderService.call(@mis_params, @request)
      end
      # EOF service_query

      def service_data
        @services.try(:each) do |service|
          receipt_date = service['_id'].to_s(:hg_date_format)
          services = service['data']

          forward_params_without_sub_specialty = forward_params(service['_id'])
          href_without_sub_specialty = @mis_params[:url] + forward_params_without_sub_specialty + back_params

          services.group_by { |s_inv| s_inv['specialty_name'] }.each do |specialtyname, specialty_wise_services|
            specialty_name = specialtyname || '-'
            specialty_wise_services.group_by { |sub_inv| sub_inv['sub_specialty_name'] }.each do |subspecialty_name, sub_specialty_wise_services|
              sub_specialty_name = subspecialty_name.present? ? subspecialty_name.titleize : '-'

              forward_params_without_department = forward_params(service['_id'], sub_specialty_wise_services.last['sub_specialty_id'])
              href_without_department = @mis_params[:url] + forward_params_without_department + back_params

              sub_specialty_wise_services.sort_by{ |inv| inv['department_order'] }.group_by { |d_inv| d_inv['department_name'] }.each do |departmentname, department_wise_services|
                department_name = departmentname || '-'

                forward_params_without_service = forward_params(
                  service['_id'], department_wise_services.last['sub_specialty_id'],
                  department_wise_services.last['department_id']
                )
                href_without_service = @mis_params[:url] + forward_params_without_service + back_params

                department_wise_services.group_by { |inv| inv['service_name'] }.each do |servicename, inv|
                  service_name = servicename.present? ? servicename : '-'
                  service_ids = inv.pluck(:service_id).uniq.join(',')
                  
                  forward_params_without_type = forward_params(
                    service['_id'], department_wise_services.last['sub_specialty_id'],
                    department_wise_services.last['department_id'], service_ids
                  )
                  href_without_type = @mis_params[:url] + forward_params_without_type + back_params

                  total_no_of_bills = services_inject_and_sum(inv, 'total_no_of_bills')
                  total_revenue = services_inject_and_sum(inv, 'total_revenue').round(2)

                  no_of_free_bills = services_inject_and_sum(inv, 'no_of_free_bills')
                  free_revenue = services_inject_and_sum(inv, 'free_bills_revenue').round(2)
                  no_of_paid_bills = services_inject_and_sum(inv, 'no_of_paid_bills')
                  paid_revenue = services_inject_and_sum(inv, 'paid_bills_revenue').round(2)
                  no_of_discounted_bills = services_inject_and_sum(inv, 'no_of_discounted_bills')
                  discounted_revenue = services_inject_and_sum(inv, 'discounted_bills_revenue').round(2)

                  if @request == 'json'
                    receipt_date = "<a href='#{href_without_sub_specialty}' data-remote='true'>#{receipt_date}</a>" 
                    sub_specialty_name = "<a href='#{href_without_department}' "\
                      "data-remote='true'>#{sub_specialty_name}</a>"
                    department_name = "<a href='#{href_without_service}' "\
                      "data-remote='true'>#{department_name}</a>"
                    service_name = "<a href='#{href_without_type}' "\
                      "data-remote='true'>#{service_name}</a>"
                  end

                  @data_array << [receipt_date, sub_specialty_name, department_name, service_name, total_no_of_bills, total_revenue, no_of_free_bills, free_revenue, no_of_paid_bills, paid_revenue, no_of_discounted_bills, discounted_revenue]
                  department_name = sub_specialty_name = receipt_date = ''
                end
              end
            end
          end
        end
      end
      # EOF service_data

      def forward_params(receipt_date, sub_specialty_id=nil, department_id=nil, bill_entry_type_id=nil)
        params_str = "&start_date=#{receipt_date}"
        params_str += "&end_date=#{receipt_date}"
        params_str += "&time_period=#{@mis_params[:time_period]}"
        params_str += "&bill_type=#{@mis_params[:bill_type]}"
        params_str += "&organisation_id=#{@mis_params[:organisation_id]}"
        params_str += "&facility_id=#{@mis_params[:facility_id]}"
        params_str += "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        params_str += "&sub_specialty_id=#{sub_specialty_id}" if sub_specialty_id.present?
        params_str += "&department_id=#{department_id}" if department_id.present?
        params_str += "&bill_entry_type_id=#{bill_entry_type_id}" if bill_entry_type_id.present?
        params_str += '&group=finance'
        params_str += '&title=service_summary'
        params_str += '&has_params=true'

        params_str
      end
      # EOF forward_params

      def back_params
        back_params_str = "&back_start_date=#{@mis_params[:start_date]}"
        back_params_str += "&back_end_date=#{@mis_params[:end_date]}"
        back_params_str += "&back_time_period=#{@mis_params[:time_period]}"
        back_params_str += "&back_group=#{@mis_params[:group]}"
        back_params_str += "&back_title=#{@mis_params[:title]}"
        back_params_str += "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_params_str += "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        back_params_str += '&has_params=true'

        back_params_str
      end
      # EOF back_params

      def services_inject_and_sum(services, fieldepartment_name)
        services.inject(0) { |sum, hash| sum + hash[fieldepartment_name.to_sym] }
      rescue StandardError
        0.00
      end
      # EOF services_inject_and_sum

      # def chceck_specialty_count(organisation_id)
      #   organisation = Organisation.find_by(id: organisation_id)
      #   organisation.specialty_ids.count
      # end
      # # EOF chceck_specialty_count

      # def chceck_specialties(facility_id)
      #   @has_specialties = Finance::StatisticService.where(
      #                     facility_id: facility_id, :specialty_id.nin => [nil, '']
      #                   ).pluck(:specialty_id).uniq.count > 1
      #   @has_sub_specialties = Finance::StatisticService.where(
      #                       facility_id: facility_id, :sub_specialty_id.nin => [nil, '']
      #                     ).pluck(:sub_specialty_id).uniq.count > 0
      # end
      # # EOF chceck_specialties
    end
  end
end
