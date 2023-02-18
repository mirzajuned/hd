module Inventory::ItemsHelper
  def self.increment_and_create_item_code(organisation_id, category_id)
    # if category.index('optical')
    #   if category.index('frame')
    #     item = Inventory::Item::Optical::Frame.where(organisation_id: organisation_id).order_by(created_at: 'desc').first
    #   elsif category.index('contact')
    #     item = Inventory::Item::Optical::Contact.where(organisation_id: organisation_id).order_by(created_at: 'desc').first
    #   elsif category.index('spectacle')
    #     item = Inventory::Item::Optical::Spectacle.where(organisation_id: organisation_id).order_by(created_at: 'desc').first
    #   elsif category.index('other')
    #     item = Inventory::Item::Optical::Other.where(organisation_id: organisation_id).order_by(created_at: 'desc').first
    #   end
    # else
    #   item = Inventory::Item.where(organisation_id: organisation_id, category: category).order_by(created_at: 'desc').first
    # end

    item = Inventory::Item.where(organisation_id: organisation_id, category_id: category_id).order_by(created_at: 'desc').first
    cat_prefix = Inventory::Category.find_by(id: category_id).prefix || 'ITEM'
    prefix = cat_prefix&.split(' ')&.join('-')
    incremented = if item
                    item.item_code.split('-').last.to_i + 1
                  else
                    1000
                  end
    "INV-#{prefix}-#{incremented}"

    # case category
    # when 'medication'
    #   "INV-MED-#{incremented}"
    # when 'stockable'
    #   "INV-STK-#{incremented}"
    # when 'implant'
    #   "INV-IMPL-#{incremented}"
    # when 'consumable'
    #   "INV-CNSM-#{incremented}"
    # when 'miscellaneous'
    #   "INV-MISC-#{incremented}"
    # when 'asset'
    #   "INV-ASST-#{incremented}"
    # when 'optical_frame'
    #   "INV-OP-FRM-#{incremented}"
    # when 'optical_contact'
    #   "INV-OP-CNT-#{incremented}"
    # when 'optical_spectacle'
    #   "INV-OP-SPT-#{incremented}"
    # when 'optical_other'
    #   "INV-OP-OTH-#{incremented}"
    # when 'intraocular_lens'
    #   "INV-OP-ITC-#{incremented}"
    # end
  end

  def self.increment_and_create_variant_no(item_id, item_code, organisation_id)
    variant = Inventory::Item::Variant.where(organisation_id: organisation_id, item_id: item_id)
                                      .order_by(created_at: 'desc').first
    incremented = if variant
                    variant.variant_code.split('-').last.to_i + 1
                  else
                    100
                  end
    "#{item_code}-#{incremented}"
  end

  def self.increment_and_create_lot_no(variant_id, variant_code, organisation_id)
    lot = Inventory::Item::Lot.where(organisation_id: organisation_id, variant_id: variant_id, :lot_code.ne => nil)&.last
    incremented = if lot
                    lot.lot_code.split('-').last.to_i + 1
                  else
                    1000
                  end
    "#{variant_code}-#{incremented}"
  end

  def self.increment_and_create_lot_unit_no(lot_id, lot_code, organisation_id)
    lot_unit = Inventory::Item::LotUnit.where(organisation_id: organisation_id, lot_id: lot_id, :lot_unit_code.ne => nil)&.last
    incremented = if lot_unit
                    lot_unit.lot_unit_code.split('-').last.to_i + 1
                  else
                    100
                  end
    "#{lot_code}-#{incremented}"
  end

  def self.increment_and_create_batch_no(item_id, organisation_id)
    item = Inventory::Item.where(organisation_id: organisation_id, id: item_id).first
    lot = item.lots.where(self_batched: true).order_by(created_at: 'desc').first
    incremented = if lot
                    lot.batch_no.split('-').last.to_i + 1
                  else
                    1000
                  end

    category = item.category
    case category
    when 'medication'
      "BCH-MED-#{incremented}"
    when 'consumable'
      "BCH-CNSM-#{incremented}"
    when 'stockable'
      "BCH-STK-#{incremented}"
    when 'implant'
      "BCH-IMPL-#{incremented}"
    when 'miscellaneous'
      "BCH-MISC-#{incremented}"
    when 'asset'
      "BCH-ASST-#{incremented}"
    when 'optical'
      "BCH-OPT-#{incremented}"
    end
  end
end

# to_bool method, convert anything to boolean
module ToBoolean
  def to_bool
    return true if self == true || to_s.strip =~ /^(true|yes|y|1)$/i

    false
  end
end

class NilClass; include ToBoolean; end
class TrueClass; include ToBoolean; end
class FalseClass; include ToBoolean; end
class Numeric; include ToBoolean; end
