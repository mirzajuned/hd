class OtInventoryInvoiceJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    ipdrecord = IpdRecord.find(args[0])
    admission = Admission.find_by(:id => ipdrecord.admissionid)
    facility = Facility.find_by(:id => admission.facility_id)

    if ipdrecord.ot_inventory_items
      ot_invoice = Invoice::Inventories::DepartmentInvoice.new(:current_department_id => "309988001_387713003", :patient_id => ipdrecord.patientid, :admission_id => ipdrecord.admissionid, :facility_id => facility.id)
      ot_invoice.recipient = Patient.find(ipdrecord.patientid).fullname
      # ot_invoice.appointment_id
      ot_invoice.save(:validate => false)
      ipdrecord.ot_inventory_items.try(:each) do |item|
        unless item["description"] == '' && item["batch_no"] == '' && item["quantity"] == ''

          ot_inventory_find = Inventory::Department::Item.find(:id => item['inventory_item_id'], :department_id => "309988001_387713003")
          # ot_invoice_existing.item.each do |existing_item|
          # unless (existing_item.inventory_item_id == item.inventory_item_id && existing_item.description == item.description) || (existing_item.description == item.description && existing_item.inventory_item_id == 'non_inventory_item' && existing_item.batch_no == item.batch_no)
          if ot_inventory_find
            unless item["quantity"].to_i > ot_inventory_find.stock
              lots = ot_inventory_find.lots.where(empty: false).order('expiry asc')
              quantity = item["quantity"].to_i
              lots.each do |lot|
                if quantity >= lot.stock
                  quantity = quantity - lot.stock
                  lot.update_attributes(stock: 0, empty: true)
                elsif lot.stock > quantity
                  lot.update_attributes(stock: lot.stock - quantity)
                  quantity = lot.stock - quantity
                end
              end
            end
            ot_inventory_find.update_attributes(:stock => ot_inventory_find.stock.to_i - item['quantity'].to_i)
            ot_item = ot_invoice.items.new(:description => item['description'], :batch_no => item['batch_no'], :quantity => item['quantity'], :billable => item['billable'])
            ot_item.list_price = ot_inventory_find.lots.first.list_price
            # ot_item.barcode = ot_inventory_find.lots.first.barcode
            ot_item.price = ot_inventory_find.lots.first.price
            ot_item.mark_up = ot_inventory_find.lots.first.mark_up
            ot_item.mrp = ot_inventory_find.lots.first.mrp
            ot_item.vendor = ot_inventory_find.lots.first.vendor
            # ot_item.manufacturer = ot_inventory_find.lots.first.manufacturer
            # ot_item.expiry = ot_inventory_find.lots.first.expiry
            # ot_item.vat = ot_inventory_find.lots.first.vat
          else
            ot_item = ot_invoice.items.new(:description => item['description'], :batch_no => item['batch_no'], :quantity => item['quantity'], :billable => item['billable'], :non_inventory_item => true)
          end

          ot_item.save
          # end
          # end
        end
      end
    end
  end
end
