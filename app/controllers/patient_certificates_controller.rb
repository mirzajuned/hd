class PatientCertificatesController < ApplicationController
  before_action :set_certificate, only: [:edit, :update]

  def new
    @patient = Patient.find_by(:id => params[:patientid])
    @certificatetype = params[:certificatetype]
    @certificate = PatientCertificate.new
    @formbuttons = "patientcertificatebuttons"
    respond_to do |format|
      format.js { render "patients/new_patient_certificate", :layout => false }
    end
  end

  def edit
    @patient = Patient.find_by(:id => params[:patientid])
    @certificatetype = params[:certificatetype]
    @formbuttons = "patientcertificateupdatebuttons"
    respond_to do |format|
      format.js { render "patients/new_patient_certificate", :layout => false }
    end
  end

  def create
    @patient = Patient.find_by(:id => params[:certificate][:patientid])
    @certificate = PatientCertificate.new(certificate_params)
    @certificatetype = params[:certificate][:certificatetype]
    @formbuttons = "patientcertificateeditbuttons"
    respond_to do |format|
      if @certificate.save
        format.js { render "patients/review_patient_certificate", :layout => false }
      else
        format.js { render "patients/new_patient_certificate", :layout => false }
      end
    end
  end

  def update
    @patient = Patient.find_by(:id => params[:certificate][:patientid])
    @certificatetype = params[:certificate][:certificatetype]
    @formbuttons = "patientcertificateeditbuttons"
    respond_to do |format|
      if @certificate.update(certificate_params)
        format.js { render "patients/update_patient_certificate", :layout => false }
      else
      end
    end
  end

  def print
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_certificate
    @certificate = PatientCertificate.find_by(:id => params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def certificate_params
    params.require(:certificate).permit(:drname, :salutation, :patientname, :guardian, :guardianname, :patientgender, :occupation, :address_1, :address_2, :city, :state, :pincode, :workeffectivedate, :identification1, :identification2, :certificatetype, :patientage, :patientid)
  end
end
