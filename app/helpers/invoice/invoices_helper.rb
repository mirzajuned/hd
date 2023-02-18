module Invoice::InvoicesHelper
  def self.mop_list(country_id)
    if country_id == 'IN_108'
      mop_list = ['', 'Cash', 'Card', 'Paytm', 'Google Pay', 'PhonePe', 'Online Transfer', 'Cheque', 'Others']
    else
      mop_list = ['', 'Cash', 'Card', 'Online Transfer', 'Cheque', 'Others']
    end
  end

  def self.entry_type_tag(entry_type)
    if entry_type == 'service'
      "<span class='badge #{entry_type}>S</span>"
    elsif entry_type == 'surgery_package'
      "<span class='badge #{entry_type}>P</span>"
    elsif entry_type == 'bill_of_material'
      "<span class='badge #{entry_type}>I</span>"
    end 
  end

  def self.draft_class(is_draft)
    (is_draft == true) ? 'is-draft-bg' : ''
  end

  def self.draft_text(is_draft)
    (is_draft == true) ? ' - Draft' : ''
  end

  def self.save_caption(is_draft)
    (is_draft == true) ? 'Save as Draft' : 'Save Final Bill'
  end

  def self.edit_caption(is_draft)
    (is_draft == true) ? 'Edit Draft Bill' : 'Edit'
  end

  def self.draft_note(is_draft)
    (is_draft == false) ? "<b style='color: red;'>Note: </b><i>Once a final bill is saved you will no longer be able to remove items or make changes to the transactions saved.</i>" : ''
  end

  def self.cancelled_text(title, is_cancelled, is_header=false)
    header = title
    if is_cancelled == true
      header += " - Cancelled"
    end
    header
  end

  def self.amount_caption(is_first_refund)
    (is_first_refund == true) ? 'Received Amount' : 'Remaining Amount'
  end
end
