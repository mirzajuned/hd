class FeedbackFormsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:fetch_original_url, :submit_feedback_form]

  def manage_feedback
    @feedback_setting = FeedbackSetting.where(organisation_id: current_user.organisation_id)
    @opd_setting = @feedback_setting.find_by(set_type: 'opd')
    @discharge_setting = @feedback_setting.find_by(set_type: 'discharge')

    respond_to do |format|
      format.js {}
    end
  end

  def edit
    @set_type = params[:set_type]
    @feedback_setting = FeedbackSetting.find_by(id: params[:id])

    respond_to do |format|
      format.js {}
    end
  end

  def update
    @set_type = params[:set_type]
    @feedback_setting = FeedbackSetting.find_by(id: params[:id])
    if params[:feedback_setting].present?
      @feedback_setting.update!(feedback_form_update_params)
    end

    respond_to do |format|
      format.js {}
    end
  end

  def feedback_form_status
    @feedback_setting = FeedbackSetting.find_by(id: params[:data_id])
    if params[:data_from] == "opd"
      @feedback_setting.update(opd_feedback_feature: params[:feedback_status])
    elsif params[:data_from] == "discharge"
      @feedback_setting.update(discharge_feedback_feature: params[:feedback_status])
    end

    respond_to do |format|
      format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Notice', text: '#{params[:data_from].capitalize} Feedback Status updated', type: 'success' }); notice.get().click(function(){ notice.remove() });" }
    end
  end

  def fetch_original_url
    @url = PatientFeedbackUrl.find_by(short_url: params[:id])

    if @url.present? && @url.is_active
      @organisation = Organisation.find_by(id: @url.organisation_id)
      @logo = @organisation.logo.to_s
      @feedback_setting = FeedbackSetting.find_by(id: @url.feedback_setting_id)
      @feedback_questions = @feedback_setting.feedback_question_sets
      @organisation_name = @url.organisation_name.present? ? @url.organisation_name : Organisation.find_by(id: @url.organisation_id).name

      file_name = "/feedback_forms/questions_feedback_form"
    else
      file_name = "/feedback_forms/link_expired"
    end

    respond_to do |format|
      format.html { render "#{file_name}" }
    end
  end

  def submit_feedback_form
    params.permit!
    @url = PatientFeedbackUrl.find_by(id: params[:id])

    if @url.present?
      # ========================>rating logic start
      total_count = 0
      total_rating = 0
      rating_array = []
      params[:feedback_form][:question]
      @feedback_setting = FeedbackSetting.find_by(id: @url.feedback_setting_id)

      rating_array = [params[:feedback_form][:rating0], params[:feedback_form][:rating1], params[:feedback_form][:rating2], params[:feedback_form][:rating3], params[:feedback_form][:rating4], params[:feedback_form][:rating5], params[:feedback_form][:rating6]]

      total_count = rating_array.reject(&:blank?).count
      @avg_rating = rating_array.map { |ele| ele.to_f }.inject(:+) / total_count
      params[:feedback_form][:average_rating] = @avg_rating
      # ========================>rating logic ends

      if params[:patient_id].present?
        params[:feedback_form][:is_patient] = true
        params[:feedback_form][:patient_id] = params[:patient_id]
        @patient = Patient.find_by(id: params[:patient_id])

        if @patient.present?

          update_patient_feedback
        end

        params[:feedback_form][:salutation] = @patient.try(:salutation)
        params[:feedback_form][:fullname] = @patient.try(:fullname)
        params[:feedback_form][:mobilenumber] = @patient.try(:mobilenumber)
        params[:feedback_form][:email] = @patient.try(:email)
        params[:feedback_form][:address_1] = @patient.try(:address_1)
        params[:feedback_form][:address_2] = @patient.try(:address_2)
        params[:feedback_form][:age] = @patient.try(:age)
        params[:feedback_form][:dobyear] = @patient.try(:dobyear)
        params[:feedback_form][:city] = @patient.try(:city)
        params[:feedback_form][:state] = @patient.try(:state)
        params[:feedback_form][:facility_id] = @url.try(:facility_id).to_s
        params[:feedback_form][:organisation_id] = @url.try(:organisation_id).to_s
        params[:feedback_form][:patient_id] = @url.try(:patient_id).to_s
        params[:feedback_form][:doctor_id] = @url.try(:doctor_id).to_s

      end

      @feedback = Feedback.new(feedback_params)
      @feedback.save!
      @feedback_setting.feedback_question_sets.each do |question_data|
        @feedback.feedback_question_sets.create(question_data.attributes)
      end

      data_to_send = {}
      if params[:feedback_form].present?
        data_to_send["usability"] = params[:feedback_form][:rating0].to_f
        data_to_send["waiting"] = params[:feedback_form][:rating1].to_f
        data_to_send["cleanliness"] = params[:feedback_form][:rating2].to_f
        data_to_send["overallcare"] = params[:feedback_form][:rating3].to_f
        data_to_send["recommendation"] = params[:feedback_form][:rating4].to_f
        data_to_send["average_rating"] = params[:feedback_form][:average_rating].to_f
      end
      @url.update(is_active: false)
      Analytics::CreateService.call(data_to_send.to_json, "no_user", @url.try(:facility_id).to_s, "feedback")
      respond_to do |format|
        format.html { render 'feedback_forms/thank_you_page' }
      end
    else
      head :ok
    end
  end

  private

  def feedback_params
    params.require(:feedback_form).permit(:salutation, :fullname, :mobilenumber, :email, :address_1, :address_2, :age, :dobyear, :city, :state, :rating1, :rating2, :rating3, :rating4, :rating5, :rating6, :rating7, :referral_rating, :referral_rating_comment, :average_rating, :feedback_note, :type, :is_patient, :patient_id, :facility_id, :user_id, :organisation_id, :extra_comments, :doctor_id)
  end

  def feedback_form_update_params
    params.require(:feedback_setting).permit(:set_type, :feedback_question_sets_attributes => [:id, :type, :question_field, :_destroy])
  end

  def update_patient_feedback
    pat_feedback = Feedback.collection.aggregate([{ "$match" => { "patient_id" => @patient.id } }, { "$group" => { "_id" => "$patient_id", "total_rating" => { "$sum" => "$average_rating" }, "count" => { "$sum" => 1 } } }]).to_a[0]

    if pat_feedback.present?
      patient_avg_rating = (pat_feedback["total_rating"] + @avg_rating) / (pat_feedback["count"] + 1)
      @patient.update(rating: patient_avg_rating)
    else
      @patient.update(rating: @avg_rating)
    end
  end
end
