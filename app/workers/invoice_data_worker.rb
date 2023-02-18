class InvoiceDataWorker
  include Sidekiq::Worker

  def perform(invoice_id)
    invoice_data = Invoice.find(invoice_id)
    user_id = invoice_data.appointment.user.id
    facility_id = invoice_data.appointment.facility.id
    # data manupulation for invoice_day_earning
    if invoice_day_earnings = InvoiceDayEarning.find_by(:user_id => user_id, :facility_id => facility_id, :date => Date.current)
      invoice_day_earnings.inc(total_earnings: invoice_data.total)
    else
      invoice_day_earnings = InvoiceDayEarning.new(:total_earnings => invoice_data.total, :user_id => user_id, :facility_id => facility_id, :date => invoice_data.created_at.to_date)
      invoice_day_earnings.save
    end

    # data manupulation for service_day_earning
    invoice_data.services.each do |each_service|
      if service_day_earnings = ServiceDayEarning.find_by(:user_id => user_id, :facility_id => facility_id, :date => Date.current, :service_name => each_service.label)
        service_day_earnings.inc(total_earnings: (each_service.unit_price * each_service.total_units))
      else
        service_day_earnings = ServiceDayEarning.new(:total_earnings => (each_service.unit_price * each_service.total_units), :user_id => user_id, :facility_id => facility_id, :date => invoice_data.created_at.to_date, :service_name => each_service.label)
        service_day_earnings.save
      end
    end
  end
end
