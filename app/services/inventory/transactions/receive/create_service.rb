module Inventory::Transactions::Receive::CreateService
  def self.call(transaction_id)
    transfer_transaction = Inventory::Transaction::Transfer.find_by(id: transaction_id)
    transfer_user_name = User.find_by(id: transfer_transaction.user_id).try(:fullname)
    receive_transaction = Inventory::Transaction::Receive.new

    receive_transaction.note = ''
    receive_transaction.status = 'Pending'

    receive_transaction.transfer_user_name = transfer_transaction.entered_by
    receive_transaction.entry_type = transfer_transaction.entry_type
    receive_transaction.transfer_user_id = transfer_transaction.user_id
    receive_transaction.transfer_id = transfer_transaction.id
    receive_transaction.transfer_date = transfer_transaction.transaction_date
    receive_transaction.transfer_time = transfer_transaction.transaction_time
    receive_transaction.transfer_note = transfer_transaction.note
    receive_transaction.transfer_order_id = transfer_transaction.transfer_order_id
    receive_transaction.transfer_store_id = transfer_transaction.store_id
    receive_transaction.transfer_department_name = transfer_transaction.department_name
    receive_transaction.transfer_department_id = transfer_transaction.department_id
    receive_transaction.transfer_store_name = transfer_transaction.store_name
    receive_transaction.store_id = transfer_transaction.receive_store_id
    receive_transaction.store_name = transfer_transaction.receive_store_name
    receive_transaction.facility_id = transfer_transaction.facility_id
    receive_transaction.organisation_id = transfer_transaction.organisation_id
    receive_transaction.receive_display_id = InventoryHelper.increment_and_create_receive_display_number(
      transfer_transaction.organisation_id
    )
    if transfer_transaction.requisition_id.present?
      receive_transaction.requisition_display_id = transfer_transaction&.requisition_received&.requisition_display_id
      receive_transaction.requisition_id = transfer_transaction&.requisition_id
      receive_transaction.requisition_received_id = transfer_transaction&.requisition_received_id
      receive_transaction.optical_order_id = transfer_transaction&.optical_order_id
      receive_transaction.requisition_order_id = transfer_transaction&.requisition_id
    end
    transfer_transaction.update(receive_id: receive_transaction.id) if receive_transaction.save!
  end
end
