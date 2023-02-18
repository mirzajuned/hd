class CreateMultipleRolRuleJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    user = User.find_by(id: args[1])
    inventory_rol_rule = args[0]

    inventory_rol_rule.each do |rol_rule|
      rol_rule_id = rol_rule[1][:id]
      is_updated = rol_rule[1][:is_updated]
      next unless is_updated == 'true'
      
      @rol_rule = (Inventory::RolRule.find_by(id: rol_rule_id.to_s, store_id: rol_rule[1][:store_id]) if rol_rule_id.present?) || Inventory::RolRule.new
      
      @rol_rule.is_active = rol_rule[1][:is_active].present? ? rol_rule[1][:is_active] : true
      @rol_rule.store_id = rol_rule[1][:store_id]
      @rol_rule.store_name = rol_rule[1][:store_name]
      @rol_rule.variant_id = rol_rule[1][:variant_id]
      @rol_rule.variant_reference_id = rol_rule[1][:variant_reference_id]
      @rol_rule.item_id = rol_rule[1][:item_id]
      @rol_rule.variant_name = rol_rule[1][:variant_name]
      @rol_rule.rol_value = rol_rule[1][:rol_value]
      @rol_rule.max_value = rol_rule[1][:max_value]
      @rol_rule.min_value = rol_rule[1][:min_value]

      activity_log = { user_name: user.fullname, event_time: Time.current, rol_value: @rol_rule.rol_value,
                       max_value: @rol_rule.max_value, min_value: @rol_rule.min_value }
      @rol_rule.activity_log << activity_log

      next if @rol_rule.store_id.nil? || @rol_rule.variant_id.nil? || @rol_rule.rol_value.nil?

      @rol_rule.user_id = user.id
      @rol_rule.organisation_id = user.organisation_id
      @rol_rule.save!
    end
  end
end
