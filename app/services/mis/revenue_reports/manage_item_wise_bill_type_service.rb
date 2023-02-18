module Mis::RevenueReports
  class ManageItemWiseBillTypeService
    class << self
      def call(invoice_id)
        mis_logger = Logger.new("#{Rails.root}/log/mis_logger.log")
        invoice = Invoice.find_by(id: invoice_id)
        invoice_update = invoice.try(:updated_at)
        organisation_id = invoice.organisation_id
        facility_id = invoice.facility_id
        facility = Facility.find_by(id: facility_id)
        facility_name = facility.try(:name)
        facility_timezone = facility.try(:time_zone)
        
        department_id = invoice.department_id

        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)

        invoice.services.where(:entry_type.ne => 'bill_of_material', :description.ne => nil).each do |service|
          bill_type = get_bill_type(service.net_item_price, service.discount_amount)
          # get details from service
          service_type, service_type_code, service_type_code_name, service_group_id, service_sub_group_id, package_group_id, package_uniq_id = service_details(service)
          # end get details from service

          service_group_name = ServiceGroup.find_by(id: service_group_id).try(:name)
          service_sub_group_name = ServiceSubGroup.find_by(id: service_sub_group_id).try(:name)

          f_mis_revenue = Finance::ItemWiseBillTypeSummary.find_or_create_by(
            item_id: service.id, invoice_id: invoice.id, facility_id: facility_id
          )

          f_mis_revenue.organisation_id = organisation_id
          f_mis_revenue.facility_name = facility_name
          f_mis_revenue.facility_timezone = facility_timezone
          f_mis_revenue.department_id = department_id
          f_mis_revenue.department_name = department_name
          f_mis_revenue.department_order = department_order

          f_mis_revenue.item_entry_date = service.try(:item_entry_date).to_date
          f_mis_revenue.item_entry_datetime = service.try(:item_entry_date)
          f_mis_revenue.bill_type = bill_type
          f_mis_revenue.bill_entry_type = service.entry_type
          f_mis_revenue.bill_entry_type_id = service.description
          f_mis_revenue.service_type = service_type
          f_mis_revenue.service_type_code = service_type_code
          f_mis_revenue.service_type_code_name = service_type_code_name
          f_mis_revenue.service_group_id = service_group_id
          f_mis_revenue.service_group_name = service_group_name
          f_mis_revenue.service_sub_group_id = service_sub_group_id
          f_mis_revenue.service_sub_group_name = service_sub_group_name
          f_mis_revenue.package_group_id = package_group_id
          f_mis_revenue.package_uniq_id = package_uniq_id
          f_mis_revenue.added_by_id = service.added_by_id
          f_mis_revenue.added_by_display_fields = get_details(
            'User', service.added_by_id, ['fullname', 'mobilenumber', 'email', 'designation']
          )
          f_mis_revenue.advised_by_id = service.advised_by_id
          f_mis_revenue.advised_by_display_fields = get_details(
            'User', service.advised_by_id, ['fullname', 'mobilenumber', 'email', 'designation']
          )
          f_mis_revenue.patient_id = invoice.patient_id
          patient_current_age, patient_age_present = Patientdata::CurrentAge.call(invoice.patient_id.to_s)
          patient_display_fields = get_details(
            'Patient', invoice.patient_id, [
              'fullname', 'mobilenumber', 'email', 'gender', 'age', 'exact_age',
              'displayage', 'dob', 'dob_day', 'dob_month', 'dob_year', 'is_approx_dob'
            ]
          )
          patient_display_fields.merge!({
            'patient_current_age': patient_current_age, 'patient_age_present': patient_age_present
          })
          f_mis_revenue.patient_display_fields = patient_display_fields
          f_mis_revenue.save!

          invoice.migration = true
          invoice.update(is_migrated: true)
          invoice.update(updated_at: invoice_update)
        end
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
      # end call method

      def get_bill_type(net_amount, discount)
        bill_type = ''
        if net_amount.to_f > 0 && discount.to_f > 0
          bill_type = 'paid_discounted'
        elsif net_amount.to_f == 0  && discount.to_f > 0
          bill_type = 'free_discounted'
        elsif net_amount.to_f > 0 && discount.to_f == 0
          bill_type = 'paid'
        else
          bill_type = 'free'
        end
        bill_type
      end
      # end get_bill_type

      def service_details(service)
        package_group_id = package_uniq_id = service_type = service_type_code = service_type_code_name = nil
        if service.entry_type == 'surgery_package'  # SurgeryPackage
          surgery_package = SurgeryPackage.find_by(id: service.try(:description))
          service_type = surgery_package.try(:service_type)
          service_type_code = surgery_package.try(:service_type_code)
          service_type_code_name = surgery_package.try(:service_type_code_name)
          service_group_id = surgery_package.try(:service_group_id)
          service_sub_group_id = surgery_package.try(:service_sub_group_id)
          package_group_id = surgery_package.try(:package_group_id)
          package_uniq_id = surgery_package.try(:package_uniq_id)
        elsif service.entry_type == 'service' # PricingMaster
          pricing_master = PricingMaster.find_by(id: service.try(:description))
          service_master = pricing_master.try(:service_master)
          if service_master.present?
            service_type = service_master.service_type
            service_type_code = service_master.service_type_code
            service_type_code_name = service_master.service_type_code_name
          end
          service_group_id = pricing_master.try(:service_group_id)
          service_sub_group_id = pricing_master.try(:service_sub_group_id)
        else # BOM -> Inpatient::BillOfMaterial
          # BOM does not contain service details 
        end
        [service_type, service_type_code, service_type_code_name, service_group_id, service_sub_group_id, package_group_id, package_uniq_id]
      end
      # end service_details 

      def get_details(table_name, id, fields)
        field_hash = {}
        record = table_name.constantize.find_by(id: id)
        if record.present?
          fields.each do |field|
            field_hash.merge!(:"#{field}" => record[field])
          end
        end
        field_hash
      end
      # end get_details
    end
  end
end
