class InventoryMailer < ActionMailer::Base
  default from: Global.send('default_email_address').try('email_address')

  def send_mail(params)
    @report = MailRecordTracker.find_by(id: params[:id])
    @user = User.find_by(id: @report[:sender_details][:sender_id])
    purchase_order = Inventory::Order::Purchase.find_by(id: @report[:record_details][:record_id])
    EmailJobs::GenerateReportPdf.perform_now(params)
    @record_name = 'Purchse Order'

    @report.update(email_delivered: true)
    purchase_order.update(email_delivered: true)
    file_path = "#{Rails.root}/public/mail_pdfs/patient_record_#{@report.id}.pdf"

    if File.exist?(file_path)
      read_file_path = File.read(file_path)
      attachments['Purchse Order.pdf'] = {
        mime_type: 'application/pdf',
        content: read_file_path
      }
    end

    mail(
      to: @report.receiver_details['vendor_email']&.split(',')&.join(' , '),
      cc: '',
      subject: @report.subject.to_s
    )

    File.delete(file_path) if File.exist?(file_path)
  end
end
