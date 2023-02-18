module Mis::RevenueReports
  class ManageInvoiceServiceWiseService
    class << self
      def call(invoice_id, mis_logger=nil)
        mis_logger ||= Logger.new("#{Rails.root}/log/mis_service_logger.log")
        invoice = Invoice.find_by(id: invoice_id)
        organisation_id = invoice.organisation_id
        facility_id = invoice.facility_id
        facility = Facility.find_by(id: facility_id)
        facility_name = facility.try(:name)
        facility_timezone = facility.try(:time_zone)
        
        department_id = invoice.department_id
        department = Department.find_by(id: department_id)
        department_name = department.try(:display_name)
        department_order = department.try(:order)

        invoice_specialty_id = invoice.try(:specialty_id)
        all_roles = Global.send('user_roles')
        all_roles = JSON.parse(all_roles.to_json)

        invoice_type = invoice._type; i_type = ''
        if department_id.in?(['485396012', '486546481'])
          i_type = invoice_type.to_s.split(':')[-1].underscore
        elsif department_id == '50121007'
          i_type = 'optical'
        elsif department_id == '284748001'
          i_type = 'pharmacy'
        end
        
        invoice_display_hash = {
          'bill_number': invoice.try(:bill_number), 'created_at': invoice.created_at,
          'type': i_type, 'specialty_id': invoice_specialty_id, 'bill_type': invoice.try(:invoice_type)
        }

        # Patient Information
        patient_id = invoice.try(:patient_id)
        patient_display_fields = {}
        if patient_id.present?
          patient_current_age, patient_age_present = Patientdata::CurrentAge.call(patient_id.to_s)
          patient_display_fields = get_details(
            'Patient', patient_id, [
              'fullname', 'mobilenumber', 'email', 'gender', 'age', 'exact_age',
              'displayage', 'dob', 'dob_day', 'dob_month', 'dob_year', 'is_approx_dob',
              'patient_identifier_id', 'patient_mrn', 'commune', 'city', 'district',
              'state', 'pincode', 'address_1', 'address_2', 'location_id', 'area_manager_id',
              'area_manager_name'
            ]
          )
          patient_display_fields.merge!({
            'patient_current_age': patient_current_age, 'patient_age_present': patient_age_present
          })
        end
        # EOF Patient Information

        # Payer Information
        payer_hash = {}
        if invoice.payer_master_id.present?
          payer = PayerMaster.find_by(id: invoice.payer_master_id)
          payer_hash = { 'payer_id': payer.id.to_s, 'payer_name': payer.display_name }
        end
        # EOF Payer Information


        invoice.try(:services).where(:description.ne => nil).each do |service|
          service_unit_price = service.non_taxable_amount
          invoice_unit_price = service.unit_price

          discount_amount = service.try(:discount_amount) || 0
          offer_amount = service.try(:offer_amount) || 0
          total_discount_offer_amount = discount_amount + offer_amount
          discount_type = get_discount_type(service.net_item_price, total_discount_offer_amount)
          percentage_off = ((100*total_discount_offer_amount)/invoice_unit_price).to_f
          # get details from service
          service_type, service_type_code, service_type_code_name, service_group_id, service_sub_group_id, package_group_id, package_uniq_id, specialty_id, specialty_name, sub_specialty_id, sub_specialty_name = service_details(service)
          # end get details from service

          service_group_name = ServiceGroup.find_by(id: service_group_id).try(:name)
          service_sub_group_name = ServiceSubGroup.find_by(id: service_sub_group_id).try(:name)

          mis_service_summary = Finance::InvoiceServiceSummary.find_or_create_by(
            service_id: service.id, invoice_id: invoice.id, facility_id: facility_id, department_id: department_id
          )

          mis_service_summary.organisation_id = organisation_id
          mis_service_summary.facility_name = facility_name
          mis_service_summary.facility_timezone = facility_timezone
          mis_service_summary.department_name = department_name
          mis_service_summary.department_order = department_order

          mis_service_summary.service_entry_date = service.try(:item_entry_date).to_date
          mis_service_summary.service_entry_datetime = service.try(:item_entry_date)
          mis_service_summary.service_name = service.try(:name)
          mis_service_summary.discount_type = discount_type
          mis_service_summary.bill_entry_type = service.try(:entry_type)
          mis_service_summary.bill_entry_type_id = service.try(:description)

          mis_service_summary.service_unit_price = service_unit_price
          mis_service_summary.invoice_unit_price = invoice_unit_price
          mis_service_summary.unit_cost_difference = (invoice_unit_price.to_f - service_unit_price.to_f)
          mis_service_summary.total_units = service.try(:total_units)
          mis_service_summary.is_advance = service.try(:is_advance)
          mis_service_summary.service_total = service.try(:service_total)
          mis_service_summary.quantity = service.try(:quantity)
          mis_service_summary.price = service.try(:price)

          mis_service_summary.tax_group_id = service.try(:tax_group_id)
          mis_service_summary.tax_inclusive = service.try(:tax_inclusive)
          mis_service_summary.non_taxable_amount = service.try(:non_taxable_amount)
          mis_service_summary.taxable_amount = service.try(:taxable_amount)
          mis_service_summary.tax_group = service.try(:tax_group)

          mis_service_summary.net_item_price = service.try(:net_item_price)
          mis_service_summary.discount_amount = discount_amount
          mis_service_summary.discount_percentage = if service.discount_percentage.present?
                                                      service.discount_percentage
                                                    elsif discount_amount.to_f > 0 && invoice_unit_price.to_f > 0
                                                      ((100*discount_amount)/invoice_unit_price).to_f
                                                    end

          mis_service_summary.discount_reason = service.try(:discount_reason)

          mis_service_summary.offer_amount = service.try(:offer_amount)
          mis_service_summary.offer_percentage = if service.offer_percentage.present?
                                                    service.offer_percentage
                                                  elsif offer_amount.to_f > 0 && invoice_unit_price.to_f > 0
                                                    ((100*offer_amount)/invoice_unit_price).to_f
                                                  end
          mis_service_summary.offer_id = service.try(:offer_id)
          mis_service_summary.offer_name = service.try(:offer_name)
          mis_service_summary.offer_code = service.try(:offer_code)

          percentage_off = 0
          percentage_off = ((100*total_discount_offer_amount)/invoice_unit_price).to_f if total_discount_offer_amount > 0
          mis_service_summary.percentage_off = percentage_off

          mis_service_summary.service_type = service_type
          mis_service_summary.service_type_code = service_type_code
          mis_service_summary.service_type_code_name = service_type_code_name
          mis_service_summary.service_group_id = service_group_id
          mis_service_summary.service_group_name = service_group_name
          mis_service_summary.service_sub_group_id = service_sub_group_id
          mis_service_summary.service_sub_group_name = service_sub_group_name
          mis_service_summary.package_group_id = package_group_id
          mis_service_summary.package_uniq_id = package_uniq_id
          mis_service_summary.specialty_id = specialty_id
          mis_service_summary.specialty_name = specialty_name
          mis_service_summary.sub_specialty_id = sub_specialty_id
          mis_service_summary.sub_specialty_name = sub_specialty_name
          mis_service_summary.added_by_id = service.try(:added_by_id)
          added_by_display_fields = get_details(
            'User', service.try(:added_by_id), ['fullname', 'mobilenumber', 'email', 'designation']
          )
          added_by = User.find_by(id: service.try(:added_by_id))
          if added_by.present?
            # added_by_roles = added_by.roles.pluck(:id, :name, :label).map{|u| {id: u[0], name: u[1], label: u[2]}}
            added_by_roles = added_by.role_ids.map{|r| [r.to_s, all_roles[r.to_s]['name'], all_roles[r.to_s]['label']]}.map{|u| {id: u[0], name: u[1], label: u[2]}}
            added_by_display_fields.merge!('roles': added_by_roles)
          end
          mis_service_summary.added_by_display_fields = added_by_display_fields
          mis_service_summary.advised_by_id = service.try(:advised_by_id)
          mis_service_summary.advised_by_display_fields = get_details(
            'User', service.try(:advised_by_id), ['fullname', 'mobilenumber', 'email', 'designation']
          )
          mis_service_summary.offer_manager_id = service.try(:offer_manager_id)
          mis_service_summary.offer_name = service.try(:offer_name)
          mis_service_summary.offer_code = service.try(:offer_code)
          mis_service_summary.offer_percentage = service.try(:offer_percentage)
          mis_service_summary.offer_amount = service.try(:offer_amount)
          mis_service_summary.offer_applied_at = service.try(:offer_applied_at)
          mis_service_summary.offer_applied_at_name = service.try(:offer_applied_at_name)
          mis_service_summary.offer_applied_by = service.try(:offer_applied_by)
          mis_service_summary.offer_applied_by_name = service.try(:offer_applied_by_name)
          mis_service_summary.offer_applied_date = service.try(:offer_applied_date)
          mis_service_summary.offer_applied_datetime = service.try(:offer_applied_datetime)
          mis_service_summary.invoice_display_fields = invoice_display_hash || {}
          mis_service_summary.patient_display_fields = patient_display_fields || {}
          mis_service_summary.payer_display_fields = payer_hash || {}
          mis_service_summary.save!
        end
        invoice.migration = true
        invoice.set(is_migrated: true)
      # rescue StandardError => e
      #   mis_logger.error(" === error in ManageRevenueService :: #{e.inspect}")
      end
      # end call method

      def get_discount_type(net_amount, discount)
        discount_type = ''
        if net_amount.to_f > 0 && discount.to_f > 0
          discount_type = 'paid_discounted'
        elsif net_amount.to_f == 0  && discount.to_f > 0
          discount_type = 'free_discounted'
        elsif net_amount.to_f > 0 && discount.to_f == 0
          discount_type = 'paid'
        else
          discount_type = 'free'
        end
        discount_type
      end
      # end get_discount_type

      def service_details(service)
        service_type = service_type_code = service_type_code_name = package_group_id = package_uniq_id = nil
        service_group_id = service_sub_group_id = specialty_id = specialty_name = nil
        sub_specialty_id = sub_specialty_name = nil
        if service.entry_type == 'surgery_package'  # SurgeryPackage
          surgery_package = SurgeryPackage.find_by(id: service.try(:description))
          service_type = service.try(:service_type) || 'P'
          service_type_code = surgery_package.try(:service_type_code)
          service_type_code_name = surgery_package.try(:service_type_code_name)
          service_group_id = surgery_package.try(:service_group_id)
          service_sub_group_id = surgery_package.try(:service_sub_group_id)
          package_group_id = surgery_package.try(:package_group_id)
          package_uniq_id = surgery_package.try(:package_uniq_id)
          package_definition = PackageDefinition.find_by(package_group_id: surgery_package.try(:package_group_id))
          specialty_id = package_definition.try(:specialty_id)
          specialty_name = Specialty.find_by(id: specialty_id).try(:name)
          sub_specialty_id = package_definition.try(:sub_specialty_id)
          sub_specialty_name = SubSpecialty.find_by(id: sub_specialty_id).try(:name)
        elsif service.entry_type == 'service' # PricingMaster
          pricing_master = PricingMaster.find_by(id: service.try(:description))
          service_master = pricing_master.try(:service_master)
          if service_master.present?
            service_type_code = service_master.service_type_code
            service_type_code_name = service_master.service_type_code_name
            specialty_id = service_master.try(:specialty_id) || nil
            specialty_name = Specialty.find_by(id: specialty_id).try(:name) || nil
            sub_specialty_id = service_master.try(:sub_specialty_id) || nil
            sub_specialty_name = SubSpecialty.find_by(id: sub_specialty_id).try(:name) || nil
          end
          service_type = service.try(:service_type) || 'S'
          service_group_id = pricing_master.try(:service_group_id)
          service_sub_group_id = pricing_master.try(:service_sub_group_id)
          
        else # BOM -> Inpatient::BillOfMaterial
          bom = Inpatient::BillOfMaterial.find_by(id: service.try(:description))
          service_type = service.try(:service_type) || 'I'
        end
        [service_type, service_type_code, service_type_code_name, service_group_id, service_sub_group_id, package_group_id, package_uniq_id, specialty_id, specialty_name, sub_specialty_id, sub_specialty_name]
      end
      # end service_details 

      def get_details(table_name, id, fields)
        field_hash = {}
        record = table_name.constantize.find_by(id: id)
        if record.present?
          fields.each do |field|
            field_hash.merge!(:"#{field}" => record.send(field))
          end
        end
        field_hash
      end
      # end get_details
    end
  end
end
