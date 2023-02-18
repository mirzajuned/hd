class RadiologyInvestigationDataController < ApplicationController
  def search
    @investigations_array = []

    if OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:disable_default_investigation)
      @custom_radiology_investigations = CustomRadiologyInvestigation.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i, :facility_id => current_facility.id, is_deleted: false).limit(50)

      @custom_radiology_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :radiology_type, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.radiology_type = investigation.investigation_type
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "CustomRadiologyInvestigation"
        investigation_struc.investigation_type_label = "CC"
        @investigations_array << investigation_struc
      end
    else
      @radiology_investigations = RadiologyInvestigationData.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i).limit(50)

      @radiology_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :radiology_type, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.radiology_type = investigation.investigation_type
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "RadiologyInvestigationData"
        investigation_struc.investigation_type_label = "C"
        @investigations_array << investigation_struc
      end

      @custom_radiology_investigations = CustomRadiologyInvestigation.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i, :facility_id => current_facility.id, is_deleted: false).limit(50)

      @custom_radiology_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :radiology_type, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.radiology_type = investigation.investigation_type
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "CustomRadiologyInvestigation"
        investigation_struc.investigation_type_label = "CC"
        @investigations_array << investigation_struc
      end
    end
  end
end
