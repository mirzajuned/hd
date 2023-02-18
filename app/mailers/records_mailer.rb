class RecordsMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')

  def send_mail(params)
    @report = MailRecordTracker.find_by(id: params[:id])

    unless @report.record_details[:record_name] == "AdverseEvent"
      EmailJobs::GenerateReportPdf.perform_now(params)
    end
    @record_name = if @report.record_details[:filename].present?
                      "#{@report.record_details[:filename]}"
                    elsif ['Invoice::Opd', 'Invoice::Ipd', 'AdvancePayment'].include? @report.record_details['record_model']
                      'Invoice'
                    elsif ['Optical Invoice', 'Pharmacy Invoice'].include? @report.record_details['record_name']
                      'Invoice'
                    elsif @report.record_details[:record_name] == "AdverseEvent"
                      'Adverse Event'
                    else
                     'Health record'
                   end

    @report.update(email_delivered: true)
    file_path = "#{Rails.root}/public/mail_pdfs/patient_record_#{@report.id}.pdf"

    if @report.record_details[:record_name] == "AdverseEvent"
      if File.exist?(file_path)
        read_file_path = File.read(file_path)
        attachments['Adverse Event Report.pdf'] = {
          mime_type: 'application/pdf',
          content: read_file_path
        }
      end

      mail(
        to: @report.receiver_details['patient_email']&.split(',')&.join(" , "),
        cc: '',
        subject: @report.subject.to_s
      )
    else
      pdf_name = if @report.record_details[:filename].present?
          "Your #{@report.record_details[:filename]}.pdf"
        elsif @report.record_details[:record_name] == 'Inventory Invoice'
          invoice = Invoice::InventoryInvoice.find_by(id: @report.record_details[:record_id])
          "Your #{invoice.department_name} Invoice.pdf"
        else
          'Your Health Record.pdf'
        end
      if File.exist?(file_path)
        read_file_path = File.read(file_path)
        attachments[pdf_name] = {
          mime_type: 'application/pdf',
          content: read_file_path
        }
      end

      mail(
        to: @report.receiver_details['patient_email'].to_s,
        cc: @report.selectedtagnames.to_s,
        subject: @report.subject.to_s
      )
    end

    File.delete(file_path) if File.exist?(file_path)
  end
end
