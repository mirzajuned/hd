# Temporary Until New Inventory Invoice Structure is creaated
class Analytics::Financial::InventoryPaymentModeJob < ActiveJob::Base
  queue_as :urgent
  def perform(invoice_id)
    invoice = Invoice.find_by(id: invoice_id)
    if invoice
      invoice_type = invoice._type.split("::")[-1].gsub("Invoice", "")

      if invoice.present?
        payment_mode = Analytics::Financial::PaymentMode.find_by(date: invoice.order_date.to_date, type: invoice_type.to_s.downcase, facility_id: invoice.facility_id.to_s) || Analytics::Financial::PaymentMode.new

        if payment_mode.present?
          payment_mode.date = invoice.order_date.to_date
          payment_mode.currency_id = invoice.currency_id
          payment_mode.currency_symbol = invoice.currency_symbol
          payment_mode.facility_id = invoice.facility_id
          payment_mode.organisation_id = invoice.organisation_id

          if invoice_type == "Pharmacy"
            payment_mode.type = "pharmacy"
            payment_mode.type_id = "284748001"
          elsif invoice_type == "Optical"
            payment_mode.type = "optical"
            payment_mode.type_id = "50121007"
          end
          if invoice.mode_of_payment == "Cash & Card" # Temporary Until Cash & Card is sorted in Inventory
            payment_mode.cash = payment_mode.cash.to_f + (invoice.total / 2)
            payment_mode.card = payment_mode.card.to_f + (invoice.total / 2)
          else
            if invoice.mode_of_payment.to_s.present?
              payment_mode_field = "payment_mode.#{invoice.mode_of_payment.to_s.gsub(' ', '_').downcase}"
              eval("#{payment_mode_field} = #{payment_mode_field} + #{invoice.total.to_f}")
            end
          end

          payment_mode.save
        end
      end
    end
  end
end
