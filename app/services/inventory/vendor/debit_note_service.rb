class Inventory::Vendor::DebitNoteService
  class << self
    def call(transaction, flow)
      vendor = Inventory::Vendor.find_by(id: transaction.vendor_id)
      note = vendor.debit_amount_breakups.new
      if transaction.entry_type == 'purchase'
        note.type = 'Purchase'
        note.total_amount = transaction.net_amount
        note.settled_amount = transaction.extra_amount_paid
        vendor.update(debit_amount: vendor.debit_amount - transaction.debit_amount&.to_f)
      else
        note.type = 'Purchase Return'
        note.settled_amount = transaction.paid_amount
        note.total_amount = transaction.return_amount
        vendor.update(debit_amount: vendor.debit_amount + transaction.debit_amount&.to_f)
      end
      note.transaction_date = transaction.transaction_date
      note.transaction_time = transaction.created_at || transaction.transaction_time
      note.amount = transaction.debit_amount
      note.store_id = transaction.store_id
      note.user_id = transaction.user_id
      note.user_name = transaction.entered_by
      note.flow = flow
      note.pending_amount = transaction.debit_amount
      note.save!
    end
  end
end
