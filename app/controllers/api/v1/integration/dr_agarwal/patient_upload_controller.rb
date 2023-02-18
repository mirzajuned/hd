module Api
  module V1
    module Integration
      module DrAgarwal
        class PatientUploadController < ActionController::Base
          include CommonHelper
          respond_to :json

          def create
            organisation = Organisation.find_by(:id => params[:organisation_id])
            patient_other_identifier = PatientOtherIdentifier.find_by(:mr_no => params[:mr_no], :organisation_id => "#{organisation.id.to_s}")
            if patient_other_identifier.nil?
              dob = ""
              age = params['p_age'].to_s
              gender = params['p_gender'].to_s
              patientdobyear = params['patientdobyear']
              reg_date = params['reg_date'].to_s

              @hg_patient = Patient.new(:fullname => params['p_name'].to_s, :gender => gender, :dob => dob, :age => age, :patientdobyear => patientdobyear, :mobilenumber => params['p_mobile'].to_s, :secondarymobilenumber => "", :contactnumber => "", :email => "", :address_1 => "", :address_2 => "", :city => "", :state => "",
                                        :pincode => "", :blood_group => "", :emergencymobilenumber => "", :reg_hosp_ids => [organisation.id.to_s],
                                        :reg_date => reg_date)

              patsplit = params['p_name'].to_s.split(" ")
              if patsplit.count == 1
                @hg_patient.firstname = patsplit[0]
              elsif patsplit.count == 2
                if patsplit[0].capitalize == "Mr." || patsplit[0].capitalize == "Mr" || patsplit[0].capitalize == "Mrs" || patsplit[0].capitalize == "Mrs." || patsplit[0].capitalize == "Dr." || patsplit[0].capitalize == "Dr"
                  @hg_patient.firstname = patsplit.join(" ")
                else
                  @hg_patient.firstname = patsplit[0]
                  @hg_patient.lastname = patsplit[1]
                end
              elsif patsplit.count > 2
                @hg_patient.lastname = patsplit[patsplit.count - 1]
                patsplit.delete_at(patsplit.count - 1)
                @hg_patient.firstname = patsplit.join(" ")
              end

              if @hg_patient.save!
                PatientIdentifier.create(:patient_id => @hg_patient.id, :organisation_id => organisation.id.to_s, :patient_org_id => CommonHelper.get_org_identifier_patient(organisation))
                PatientOtherIdentifier.create(:patient_id => @hg_patient.id, :organisation_id => organisation.id.to_s, :mr_no => params[:mr_no])
                attrs = { :patient_id => @hg_patient.id, "patientpersonalhistory_attributes" => { problems: [], "flag" => 1 }, "patientallergyhistory_attributes" => { :flag => 1, antimicrobialagents: [], nsaids: [], antifungalagents: [], antiviralagents: [], contact: [], food: [], eyedrops: [], others: '' } }
                PatientHistory.create(attrs)

                @status = "1"
                @patient_id = @hg_patient.id.to_s
                respond_to do |format|
                  format.json { render "create_patient_response", :layout => false }
                end
              else

                @status = "0"
                @patient_id = ""
                respond_to do |format|
                  format.json { render "create_patient_response", :layout => false }
                end
              end
            else

              @status = "2"
              @patient_id = patient_other_identifier.patient_id.to_s
              respond_to do |format|
                format.json { render "create_patient_response", :layout => false }
              end
            end
          end

          def upload
            params[:patient_id] = params[:patient_id]
            patient = Patient.find_by(:id => "#{params[:patient_id]}")
            params[:parent_id] = ""
            params[:parent_folder_id] = ""
            cs_pdf_filename_uploaded = PatientSummaryAssetUpload.where(:name => "#{params[:name]}", :patient_id => "#{patient.id.to_s}", is_deleted: false)
            if cs_pdf_filename_uploaded.count > 0
              @status = "2"
              respond_to do |format|
                format.json { render "upload_oldcaseheet", :layout => false }
              end
            else
              @patient_summary_asset = PatientSummaryAssetUpload.new(asset_upload_params)
              if @patient_summary_asset.save
                @status = "1"
                respond_to do |format|
                  format.json { render "upload_oldcaseheet", :layout => false }
                end
              else
                @status = "0"
                respond_to do |format|
                  format.json { render "upload_oldcaseheet", :layout => false }
                end
              end
            end
          end

          private

          def asset_upload_params
            params.permit(:name, :patient_id, :parent_id, :reported_date, :reported_time, :asset_path, :parent_folder_id, :category, :opdrecord_id).merge(:is_folder => "N", :is_custom => "Y", :is_system_defined => "N", :is_root => "N").except(:organisation_id)
          end
        end
      end
    end
  end
end
