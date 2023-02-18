class PayerMasterJobs::CloneMultipleJob < ActiveJob::Base
  queue_as :urgent

  def perform(payer_master_id, facility_ids, user_id)
    payer_master = PayerMaster.find_by(id: payer_master_id)

    facility_ids = facility_ids.split(',')
    facility_ids.each do |facility_id|
      facility_payer_master = PayerMaster.find_by(payer_uniq_id: payer_master.payer_uniq_id, facility_id: facility_id)
      if facility_payer_master.present?
        data_attributes = payer_master.attributes.merge(user_id: user_id, facility_id: facility_id,
                                                        _id: facility_payer_master.id)
        facility_payer_master.update!(data_attributes)
      else
        new_payer_master = payer_master.clone
        new_payer_master.user_id = user_id
        new_payer_master.facility_id = facility_id
        new_payer_master.save
      end
    end
  end
end
