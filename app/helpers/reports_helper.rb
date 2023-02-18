module ReportsHelper
  def payment_received_details(reciepts)
    tax_deducted = payer_difference = revenue_spilage = amount_received = 0.0
    reciepts.each do |payment|
      tax_deducted += payment.tax_deducted.to_f
      payer_difference += payment.payer_difference.to_f
      revenue_spilage += payment.other_revenue_spilage.to_f
      amount_received += payment.amount_received.to_f
    end
    [ tax_deducted, payer_difference, revenue_spilage, amount_received ]
  end

  def cash_details(breakup);end

  def card_details(breakup, text = "")
    if breakup[:card_number].present?
      text += "Card Number: #{breakup[:card_number]}"
      text += ' | ' if breakup[:card_transaction_note].present?
    end
    if breakup[:card_transaction_note].present?
      text += "Txn Note:  #{breakup[:card_transaction_note]}"
    end
  end

  def paytm_details(breakup, text = "")
    if breakup[:paytm_transaction_id].present?
      text += "Txn Id:  #{breakup[:paytm_transaction_id]}"
      text += " | " if breakup[:paytm_transaction_note].present?
    end
    if breakup[:paytm_transaction_note].present?
      text += "Txn Note:  #{breakup[:paytm_transaction_note]}"
    end
  end

  def google_pay_details(breakup, text = "")
    if breakup[:gpay_transaction_id].present?
      text += "Txn Id:  #{breakup[:gpay_transaction_id]}"
      text += " | " if breakup[:gpay_transaction_note].present?
    end
    if breakup[:gpay_transaction_note].present?
      text += "Txn Note:  #{breakup[:gpay_transaction_note]}"
    end
  end

  def phonepe_details(breakup, text = "")
    if breakup[:phonepe_transaction_id].present?
      text += "Txn Id: #{breakup[:phonepe_transaction_id]}"
      text += " | " if breakup[:phonepe_transaction_note].present?
    end
    if breakup[:phonepe_transaction_note].present?
      text += "Txn Note:  #{breakup[:phonepe_transaction_note]}"
    end
  end

  def online_transfer_details(breakup, text = "")
    if breakup[:transfer_date].present?
      text += "Date:  #{breakup[:transfer_date]}"
      text += " | " if breakup[:transfer_note].present?
    end
    if breakup[:transfer_note].present?
      text += "Txn Note:  #{breakup[:transfer_note]}"
    end
  end

  def cheque_details(breakup, text = "")
    if breakup[:cheque_date].present?
      text += "Date:  breakup[:cheque_date]"
      text += " | " if breakup[:cheque_note].present?
    end
    if breakup[:cheque_note].present?
      text += "Txn Note:  #{breakup[:cheque_note]}"
    end
  end

  def others_details(breakup, text = "")
    if breakup[:other_transaction_id].present?
      text += "Txn Id:  #{breakup[:other_transaction_id]}"
      " | " if breakup[:other_note].present?
    end
    if breakup[:other_note].present?
      text += "Txn Note:  #{breakup[:other_note]}"
    end
  end
end