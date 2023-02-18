class CreateMultipleVendorRateJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    user = User.find_by(id: args[1])
    inventory_vendor_rate = args[0]

    inventory_vendor_rate.each do |vendor_rate|
      vendor_rate_id = vendor_rate[1][:id]
      is_updated = vendor_rate[1][:is_updated]
      next unless is_updated == 'true'

      @vendor_rate= (Inventory::VendorRate.find_by(id: vendor_rate_id.to_s) if vendor_rate_id.present?) || Inventory::VendorRate.new

      @vendor_rate.is_active = vendor_rate[1][:is_active].present? ? vendor_rate[1][:is_active] : true
      @vendor_rate.vendor_id = vendor_rate[1][:vendor_id]
      @vendor_rate.vendor_group_id = vendor_rate[1][:vendor_group_id]
      @vendor_rate.vendor_group_name = vendor_rate[1][:vendor_group_name]
      @vendor_rate.vendor_name = vendor_rate[1][:vendor_name]
      @vendor_rate.variant_id = vendor_rate[1][:variant_id]
      @vendor_rate.variant_reference_id = vendor_rate[1][:variant_reference_id]
      @vendor_rate.item_id = vendor_rate[1][:item_id]
      @vendor_rate.variant_name = vendor_rate[1][:variant_name]
      @vendor_rate.rate = vendor_rate[1][:rate]
      @vendor_rate.selling_price = vendor_rate[1][:selling_price]
      @vendor_rate.activity_log = {}
      @vendor_rate.activity_log['activated'] = { user_name: user.fullname, event_time: Time.current }

      next if @vendor_rate.vendor_id.nil? || @vendor_rate.variant_id.nil?

      @vendor_rate.user_id = user.id
      @vendor_rate.organisation_id = user.organisation_id
      @vendor_rate.save!
    end
  end
end
