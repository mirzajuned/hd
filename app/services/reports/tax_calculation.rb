class Reports::TaxCalculation
  def initialize(invoice)
    # Variables
    @invoice = invoice
    @tax_collected = TaxCollected.find_by(facility_id: @invoice.facility_id.to_s, date: Date.parse(@invoice.created_at.strftime('%d/%m/%Y')), currency_id: @invoice.currency_id)
    @opd_tax = @tax_collected.try(:opd_tax).to_f
    @ipd_tax = @tax_collected.try(:ipd_tax).to_f
    @pharmacy_tax = @tax_collected.try(:pharmacy_tax).to_f
    @optical_tax = @tax_collected.try(:optical_tax).to_f
  end

  def tax_collected_details
    if @invoice.tax_breakup != []
      @invoice.tax_breakup.each do |tax_breakup|
        tax_collected_breakup(tax_breakup)
        @tax_rate = TaxRate.find_by(id: tax_breakup[:_id])
        if @tax_collected.present?
          @tax_collected.update(currency_id: @invoice.currency_id, currency_symbol: @invoice.currency_symbol, opd_tax: @opd_tax, ipd_tax: @ipd_tax, pharmacy_tax: @pharmacy_tax, optical_tax: @optical_tax)
          @tax_details = @tax_collected.tax_details.find_by(id: tax_breakup['_id'])
          if @tax_details.present?
            @tax_details.update(total: @tax_details.total + tax_breakup['amount'].to_f)
          else
            tax_detail = @tax_collected.tax_details.new(id: tax_breakup['_id'], name: tax_breakup['name'], type: @tax_rate.type, total: tax_breakup['amount'].to_f)
            tax_detail.save!
          end
        else
          @tax_collected = TaxCollected.new(organisation_id: @invoice.organisation_id.to_s, facility_id: @invoice.facility_id.to_s, date: Date.parse(@invoice.created_at.strftime('%d/%m/%Y')), currency_id: @invoice.currency_id, currency_symbol: @invoice.currency_symbol, opd_tax: @opd_tax, ipd_tax: @ipd_tax, pharmacy_tax: @pharmacy_tax, optical_tax: @optical_tax)
          if @tax_collected.save!
            tax_detail = @tax_collected.tax_details.new(id: tax_breakup['_id'], name: tax_breakup['name'], type: @tax_rate.type, total: tax_breakup['amount'].to_f)
            tax_detail.save!
          end
        end
      end
    end
  end

  def tax_recollected_details
    if @invoice.tax_breakup != []
      @invoice.tax_breakup.each do |tax_breakup|
        tax_recollected_breakup(tax_breakup)
        @tax_rate = TaxRate.find_by(id: tax_breakup[:_id])
        next unless @tax_collected.present?

        @tax_collected.update(currency_id: @invoice.currency_id, currency_symbol: @invoice.currency_symbol, opd_tax: @opd_tax, ipd_tax: @ipd_tax, pharmacy_tax: @pharmacy_tax, optical_tax: @optical_tax)
        @tax_details = @tax_collected.tax_details.find_by(id: tax_breakup['_id'])
        if @tax_details.present?
          @tax_details.update(total: @tax_details.total - tax_breakup['amount'].to_f)
          @tax_details.delete if @tax_details.total == 0.0
        end
      end
    end
  end

  private

  def tax_collected_breakup(tax_breakup)
    if @invoice._type.split('::')[-1] == 'Opd'
      @opd_tax += tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'Ipd'
      @ipd_tax += tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'PharmacyInvoice'
      @pharmacy_tax += tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'OpticalInvoice'
      @optical_tax += tax_breakup['amount'].to_f
    end
  end

  def tax_recollected_breakup(tax_breakup)
    if @invoice._type.split('::')[-1] == 'Opd'
      @opd_tax -= tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'Ipd'
      @ipd_tax -= tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'PharmacyInvoice'
      @pharmacy_tax -= tax_breakup['amount'].to_f
    elsif @invoice._type.split('::')[-1] == 'OpticalInvoice'
      @optical_tax -= tax_breakup['amount'].to_f
    end
  end
end
