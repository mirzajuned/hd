# 6   Metrics/LineLength
# 5   Metrics/AbcSize
# 1   Metrics/ClassLength
# 1   Metrics/MethodLength
# --
# 13  Total
class AdviceSetsController < ApplicationController
  before_action :authorize
  before_action :find_specialties, only: [:new, :edit]
  before_action :set_languages, only: [:new, :edit]
  before_action :advice_set, only: [:edit, :update, :destroy]

  respond_to :js, :json, :html
  layout 'loggedin'

  def new
    @advice_set = AdviceSet.new
    @level = params[:level]
    @advice_set.language_advice_subset
  end

  def create
    language_subset = params[:advice_set][:language_advice_subset_attributes]
    if language_subset.reject { |_k, las| las[:content] == '<br>' }.to_unsafe_hash.empty?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Please fill content in atleast one language', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @advice_set = AdviceSet.new(advice_set_params)
      @level = params[:advice_set][:level]

      @advice_set.save
    end
  end

  def edit
    @level = params[:level]
  end

  def update
    language_subset = params[:advice_set][:language_advice_subset_attributes]
    if language_subset.reject { |_k, las| las[:content] == '<br>' }.to_unsafe_hash.empty?
      respond_to do |format|
        format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Please fill content in atleast one language', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    else
      @level = params[:advice_set][:level]
      @advice_set.update!(advice_set_params)
    end
  end

  def destroy
    @advice_set.update_attributes(is_deleted: true)
    @level = params[:level]
  end

  def new_language_subset_form
    @level = params[:ajax][:level]
    new_language_subset_form_data(@level)
    @counter = params[:ajax][:counter]
    respond_to do |format|
      format.js {}
    end
  end

  def index
    @level = 'user'
    find_specialties

    respond_to do |format|
      format.html {}
      format.js {}
    end
  end

  def data
    @hg_advice_sets = if params[:specialty_id] == '309988001'
                        Global.ophthal_advice_option.sets
                      else
                        []
                      end
    @level = params[:level]

    if @level == 'organisation'
      organisation_level_data
    elsif @level == 'facility'
      facility_level_data
    else
      user_level_data
    end

    @s_echo = params[:sEcho]

    respond_to do |format|
      format.json {}
    end
  end

  def hg_data
    @advice_set = Global.ophthal_advice_option.sets.find { |set| set['id'] == params[:id] }
  end

  def update_set_counter
    if params[:id].length > 2
      @advice_set = AdviceSet.find_by(id: params[:id])
      @advice_set.update(counter: @advice_set.counter + 1)
    end
    head :ok
  end

  def new_advice_set_popup
    respond_to do |format|
      format.html { render 'advice_sets/new_advice_set_popup', layout: false }
    end
  end

  def save_advice_set
    AdviceSet.create(user_id: current_user.id, level: 'user', name: params[:name], specialty_id: params[:specialty_id], content: params[:content], language_advice_subset: [Hash['language' => 'English', 'content' => params[:content]]], facility_id: current_facility.id, organisation_id: current_user.organisation_id.to_s)

    if TemplatesHelper.get_speciality_folder_name(params[:specialty_id]) == 'ophthalmology'
      if current_facility.try(:show_language_support) == true
        @advice_set = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).order(counter: 'desc').map { |p| ["#{p[:name]}  (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')}) by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
      else
        @advice_set = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).order(counter: 'desc').map { |p| ["#{p[:name]}   by: #{p[:level].to_s.capitalize}", (p[:content]).to_s, { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| [(p[:name]).to_s, { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
      end
    elsif current_facility.try(:show_language_support) == true
      @advice_set = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false,  '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).order(counter: 'desc').map { |p| ["#{p[:name]} (#{p[:language_advice_subset].collect { |u| u[:language] }.join(' , ')}) by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]} (English , Hindi , Bengali , Kannada , Tamil , Telugu , Gujarati)", { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    else
      @advice_set = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false,  '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).order(counter: 'desc').map { |p| ["#{p[:name]}  by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], { 'data-id' => (p[:id]).to_s }] } + Global.ophthal_advice_option.sets.map { |p| [(p[:name]).to_s, { 'data-id' => (p[:id]).to_s }, (p[:content]).to_s] }
    end

    respond_to do |format|
      format.js {}
    end
  end

  def organisation_advice_set
    @level = 'organisation'
    find_specialties
  end

  def facility_advice_set
    @level = 'facility'
    find_specialties
  end

  private

  def set_languages
    @languages = Language.where(country_ids: current_facility.country_id)
  end

  def advice_set
    @advice_set = AdviceSet.find_by(id: params[:id])
  end

  def advice_set_params
    params.require(:advice_set).permit!
  end

  def find_specialties
    level = params[:level] || @level

    if level == 'user'
      @available_specialties = Specialty.where(:id.in => current_user.specialty_ids)
      @level_name = current_user.fullname

    elsif level == 'organisation'
      @available_specialties = Specialty.where(:id.in => current_organisation['specialty_ids'])
      @level_name = current_organisation['name']

    elsif level == 'facility'
      @available_specialties = Specialty.where(:id.in => current_facility.specialty_ids)
      @level_name = current_facility.name
    end

    @selected_specialty = params[:specialty_id] || @available_specialties.first.id
  end

  def organisation_level_data
    @advice_sets_count = AdviceSet.where(organisation_id: current_user.organisation_id, level: @level,
                                         specialty_id: params[:specialty_id], is_deleted: false,
                                         name: /#{Regexp.escape(params[:sSearch])}/i).count
    @advice_sets = AdviceSet.where(organisation_id: current_user.organisation_id, level: @level,
                                   specialty_id: params[:specialty_id], is_deleted: false, name: /#{Regexp.escape(params[:sSearch])}/i)
                            .limit(params[:iDisplayLength])
                            .offset(params[:iDisplayStart])
                            .order('name ' + params[:sSortDir_0])
    @total_advice_sets_count = AdviceSet.where(organisation_id: current_user.organisation_id, level: @level,
                                               specialty_id: params[:specialty_id], is_deleted: false).count
  end

  def facility_level_data
    @advice_sets_count = AdviceSet.where(facility_id: current_facility.id, level: @level,
                                         specialty_id: params[:specialty_id], is_deleted: false,
                                         name: /#{Regexp.escape(params[:sSearch])}/i).count
    @advice_sets = AdviceSet.where(facility_id: current_facility.id, level: @level, specialty_id: params[:specialty_id],
                                   is_deleted: false, name: /#{Regexp.escape(params[:sSearch])}/i)
                            .limit(params[:iDisplayLength])
                            .offset(params[:iDisplayStart])
                            .order('name ' + params[:sSortDir_0])
    @total_advice_sets_count = AdviceSet.where(organisation_id: current_facility.id, level: @level,
                                               specialty_id: params[:specialty_id], is_deleted: false).count
  end

  def user_level_data
    @advice_sets_count = AdviceSet.where(user_id: current_user.id, level: @level, specialty_id: params[:specialty_id],
                                         is_deleted: false, name: /#{Regexp.escape(params[:sSearch])}/i).count
    @advice_sets = AdviceSet.where(user_id: current_user.id, level: @level, specialty_id: params[:specialty_id],
                                   is_deleted: false, name: /#{Regexp.escape(params[:sSearch])}/i)
                            .limit(params[:iDisplayLength])
                            .offset(params[:iDisplayStart])
                            .order('name ' + params[:sSortDir_0])
    @total_advice_sets_count = AdviceSet.where(user_id: current_user.id, specialty_id: params[:specialty_id],
                                               level: @level, is_deleted: false).count
  end

  def new_language_subset_form_data(level)
    @advice_sets_array = if level == 'organisation'
                           AdviceSet.where(organisation_id: current_user.organisation_id, level: level)
                         elsif level == 'facility'
                           AdviceSet.where(facility_id: current_facility.id, level: level)
                         else
                           AdviceSet.where(user_id: current_user.id, level: level)
                         end
  end
end
