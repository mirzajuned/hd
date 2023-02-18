class OphthalmologyInvestigationDataController < ApplicationController
  before_action :authorize
  
  def search
    @investigations_array = []

    if OrganisationsSetting.find_by(organisation_id: current_user.try(:organisation_id)).try(:disable_default_investigation)

      @custom_ophthal_investigations = CustomOphthalInvestigation.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i, organisation_id: current_user.organisation_id.to_s, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false).limit(50)

      @custom_ophthal_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "CustomOphthalInvestigation"
        investigation_struc.investigation_type_label = "CC"
        @investigations_array << investigation_struc
      end

    else
      @ophthalmology_investigations = OphthalmologyInvestigationData.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i).limit(50)

      @ophthalmology_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "OphthalmologyInvestigationData"
        investigation_struc.investigation_type_label = "C"
        @investigations_array << investigation_struc
      end

      @custom_ophthal_investigations = CustomOphthalInvestigation.where(specality_id: params[:specality_id], investigation_name: /#{Regexp.escape(params[:search])}/i, organisation_id: current_user.organisation_id.to_s, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id.to_s, level: 'facility' }], is_deleted: false).limit(50)

      @custom_ophthal_investigations.each do |investigation|
        investigation_struc = Struct.new(:id, :name, :investigation_id, :investigation_type, :investigation_type_label).new
        investigation_struc.id = investigation._id
        investigation_struc.name = investigation.investigation_name
        investigation_struc.investigation_id = investigation.investigation_id
        investigation_struc.investigation_type = "CustomOphthalInvestigation"
        investigation_struc.investigation_type_label = "CC"
        @investigations_array << investigation_struc
      end
    end
  end
end
