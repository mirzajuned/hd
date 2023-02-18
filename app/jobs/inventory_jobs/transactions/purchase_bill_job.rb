class InventoryJobs::Transactions::PurchaseBillJob < ActiveJob::Base
	queue_as :urgent

	def perform(*args)
    transaction_id = args[0]
    current_user_id = args[1]
    action_from = args[2]
    
    user = User.find_by(id: current_user_id)
    purchase_bill = Inventory::Transaction::PurchaseBill.find_by(id: transaction_id)
    purchase_transaction_ids = purchase_bill.purchase_transaction_ids
    purchase_transaction_ids.each do |purchase_transaction_id|
      purchase_transaction = Inventory::Transaction::Purchase.find_by(id: purchase_transaction_id)
      if action_from == 'create'
        unless purchase_transaction.is_purchase_bill_created
          purchase_transaction.update!(is_purchase_bill_created: true, purchase_bill_created_by: current_user_id,
                             purchase_bill_created_on: Time.current, purchase_bill_created_by_name: user.fullname)
        end
      elsif action_from == 'approve'
        unless purchase_transaction.is_purchase_bill_approved
           purchase_transaction.update!(is_purchase_bill_approved: true, purchase_bill_approved_by: current_user_id,
                             purchase_bill_approved_on: Time.current, purchase_bill_approved_by_name: user.fullname)
        end
      elsif action_from == 'cancel'
        unless purchase_transaction.is_purchase_bill_cancelled 
           purchase_transaction.update!(is_purchase_bill_cancelled: true, purchase_bill_cancelled_by: current_user_id,
                             purchase_bill_cancelled_on: Time.current, purchase_bill_cancelled_by_name: user.fullname)
          purchase_transaction.update!(is_purchase_bill_created: false, purchase_bill_created_by: nil,
                             purchase_bill_created_on: nil, purchase_bill_created_by_name: nil)
        end
      end
    end
  end
end