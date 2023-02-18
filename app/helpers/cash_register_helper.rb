module CashRegisterHelper
  def check_cash_registers
    cash_register = CashRegister.where(:facility_id => current_facility.id)
    return cash_register.present? && cash_register.length > 0 ? true : false
  end
end
