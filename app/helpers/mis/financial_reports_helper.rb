module Mis::FinancialReportsHelper
  def self.invoice_type_dropdown
    type_list = '<ul class="dropdown-menu mis-search-toggle-off" id="invoice-type-list" '\
    'style="overflow-y: auto;max-height:400px;">'
    type_list += '<li class="invoice-type-list"><a class="invoice-type-filter" '\
    'href="#" invoice-type="all"><span class="mis-invoice-type">ALL</span></a></li>'
    type_list += '<li class="invoice-type-list"><a class="invoice-type-filter" '\
    'href="#" invoice-type="opd"><span class="mis-invoice-type">OPD</span></a></li>'
    type_list += '<li class="invoice-type-list"><a class="invoice-type-filter" href="#" '\
    'invoice-type="ipd"><span class="mis-invoice-type">IPD</span></a></li>'
    type_list += '<li class="invoice-type-list"><a class="invoice-type-filter" href="#" '\
    'invoice-type="inventory_invoice"><span class="mis-invoice-type">Inventory Invoice</span></a></li>'
    type_list += '</ul>'
    type_list.html_safe
  end

  def self.user_role_dropdown(organisation_roles)
    role_list = organisation_roles
    role_list.count
  end

  def self.bill_type_dropdown
    bill_type_list = '<ul class="dropdown-menu mis-search-toggle-off" '\
    'id="bill-type-list" style="overflow-y: auto;max-height:400px;">'
    ['all', 'cash', 'credit'].each do |b_type|
      bill_type_list += "<li class='bill-type-list'><a class='bill-type-filter' "\
      "href='#' bill-type='#{b_type}'><span class='mis-bill-type'>#{b_type.upcase}</span></a></li>"
    end
    bill_type_list += '</ul>'
    bill_type_list.html_safe
  end

  def self.rename_title(report_name)
    name = ''
    if report_name == 'finance_statistics'
      name = 'stats'
    elsif report_name == 'finance'
      name = 'summary'
    end
    name.titleize
  end

  def self.rename_advance_state(amount, state)
    final_state = state
    if state == 'None' && amount == 0
      final_state = '-'
    elsif state == 'None'
      final_state = 'Partially Settled'
    elsif state == 'Deleted'
      final_state = 'Cancelled'
    end
    final_state
  end

  def self.mop_fields(country_id)
    if country_id == 'IN_108'
      mop_list = ['cash', 'card', 'paytm', 'google_pay', 'phonepe', 'online_transfer', 'cheque', 'others']
    else
      mop_list = ['cash', 'card', 'online_transfer', 'cheque', 'others']
    end
  end
end
