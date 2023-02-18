class OutPatientTemplatesTagsController < ApplicationController
  respond_to :json

  def new_id
    new_id = OpdTemplateTag.new._id.as_json['$oid']
    respond_to do |format|
      format.json { render :json => { "_id" => new_id } }
    end
  end

  def search_chief_complaint_tags
    @results_opd_templatetags = OpdTemplateTag.any_of(tag_name_lcase: /#{Regexp.escape(params[:q])}/i, :specialty_id.in => current_user.specialty_ids, :organisation_id.in => [nil, current_user.organisation_id.to_s], :is_custom.in => ["N", "Y"], :tag_type => 33962009)
    # @results_opd_templatetags = OpdTemplateTag.any_of(tag_name_lcase: %r[#{params[:q]}], :user_id.in => [nil, current_user.id.to_s], :specialty_id.in => [nil, current_user.department_id.to_i], :organisation_id.in => [nil, current_user.organisation_id.to_s])
    respond_to do |format|
      format.json { render "templates/common/results_opd_templatetags", :layout => false }
    end
  end

  def add_chief_complaint_tag
    @new_tags_objectids = []
    if !(params[:ajax][:new_tags].nil?)
      new_tags = params[:ajax][:new_tags].split(",")
      new_tags.each_with_index() do |new_tags_value, index|
        new_tags_value_array = new_tags_value.split("#!##")
        opd_template_tag_obj = OpdTemplateTag.create(:tag_name => new_tags_value_array[1], :tag_name_lcase => new_tags_value_array[1].downcase, doctor: current_user.id.to_s, user_id: current_user.id.to_s, specialty_id: current_user.specialty_ids[0], organisation_id: current_user.organisation_id.to_s, :is_custom => "Y", :tag_type => 33962009)
        @new_tags_objectids.push("#{new_tags_value_array[0]}####{opd_template_tag_obj.id}")
      end
    end
    respond_to do |format|
      format.json { render "templates/common/add_chief_complaint_tags", :layout => false }
    end
  end

  def search_advice_tag
    @results_opd_templatetags = OpdTemplateTag.any_of(tag_name_lcase: /#{Regexp.escape(params[:q])}/i, :specialty_id.in => current_user.specialty_ids, :organisation_id.in => [nil, current_user.organisation_id.to_s], :is_custom.in => ["N", "Y"], :tag_type => 413334001)
    # @results_opd_templatetags = OpdTemplateTag.where(tag_name_lcase: %r[#{params[:q]}],user_id: current_user.id, :user_id.in => [nil, current_user.id.to_s], :specialty_id.in => [nil, current_user.department_id.to_i], :organisation_id.in => [nil, current_user.organisation_id.to_s])
    respond_to do |format|
      format.json { render "templates/common/results_opd_templatetags", :layout => false }
    end
  end

  def add_advice_tag
    @new_tags_objectids = []
    if !(params[:ajax][:new_tags].nil?)
      new_tags = params[:ajax][:new_tags].split(",")
      new_tags.each_with_index() do |new_tags_value, index|
        new_tags_value_array = new_tags_value.split("#!##")
        opd_template_tag_obj = OpdTemplateTag.create(:tag_name => new_tags_value_array[1], :tag_name_lcase => new_tags_value_array[1].downcase, doctor: current_user.id.to_s, user_id: current_user.id.to_s, specialty_id: current_user.specialty_ids[0], organisation_id: current_user.organisation_id.to_s, :is_custom => "Y", :tag_type => 413334001)
        @new_tags_objectids.push("#{new_tags_value_array[0]}####{opd_template_tag_obj.id}")
      end
    end
    respond_to do |format|
      format.json { render "templates/common/add_advice_tag", :layout => false }
    end
  end
end
