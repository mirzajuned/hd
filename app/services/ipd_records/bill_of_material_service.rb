class IpdRecords::BillOfMaterialService
  def self.call(ipd_record, operative_note, ipd_record_params)
    return unless ipd_record_params[:bill_of_material].present?

    operative_bom = ipd_record.bill_of_material.where(operative_note_id: operative_note.id)
    operative_bom.each do |bom|
      Inpatient::BillOfMaterial.find_by(id: bom.bom_id).update(operative_note_id: nil, used_in_operative_note: false,
                                                               operative_note_date: nil, operative_note_time: nil)
    end

    Inpatient::BillOfMaterial.find_by(id: operative_note.bill_of_material_id)
                             .update(operative_note_id: operative_note.id, used_in_operative_note: true,
                                     operative_note_date: Date.current, operative_note_time: Time.current)
    operative_bom.delete_all if operative_bom.present?
    ipd_record_params[:bill_of_material].each do |_k, bom|
      operative_bom = ipd_record.bill_of_material.new
      operative_bom.bom_id = bom[:bom_id]
      operative_bom.category = bom[:category]
      operative_bom.variant_code = bom[:variant_code]
      operative_bom.description = bom[:description]
      operative_bom.bom_quantity = bom[:bom_quantity]
      operative_bom.batch_no = bom[:batch_no]
      operative_bom.expiry = bom[:expiry]
      operative_bom.billable = bom[:billable]
      operative_bom.is_print = bom[:is_print]
      operative_bom.operative_note_id = operative_note.id
      operative_bom.date = Date.current
      operative_bom.time = Time.current
      operative_bom.save!
    end
  end
end
