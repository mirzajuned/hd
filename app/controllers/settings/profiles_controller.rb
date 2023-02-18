class Settings::ProfilesController < ApplicationController
  layout "loggedin"

  before_action :authorize
  before_action :find_user

  def index
  end

  def edit_user_profile
  end

  def update_user_profile
    @user.remove_user_profile_pic = true if (params[:remove_user_profile_pic] == "true")
    @user.update(user_profile_params)

    UserJobs::UpdateJob.perform_later(@user.id.to_s)
  end

  def edit_user_signature
  end

  def update_user_signature
    params[:user][:user_signature] = convert_data_uri_to_upload(params[:user][:user_signature]) if params[:user][:user_signature].present?

    @user.update(user_signature_params)

    head :ok if params[:user][:digital_signature].present?
  end

  def edit_education_information
  end

  def update_education_information # Needs Work
    params.permit!
    @data = params["user"]["education_qualification"]
    if params["index"].present? # edit
      @user.education_qualification[params["index"].to_i].update(@data.to_h)
    else # new
      @user.education_qualification.push << @data.to_h
    end
    @user.save
  end

  def delete_education_information
    if params[:index].present?
      @user.pull(education_qualification: @user.education_qualification[params[:index].to_i])
    end
  end

  def edit_work_experience
  end

  def update_work_experience # Needs Work
    params.permit!
    @data = params["user"]["work_experience"]
    if params["index"].present? # edit
      @user.work_experience[params["index"].to_i].update(@data.to_h)
    else # new
      @user.work_experience.push << @data.to_h
    end
    @user.save
  end

  def delete_work_experience
    if params[:index].present?
      @user.pull(work_experience: @user.work_experience[params[:index].to_i])
    end
  end

  private

  def find_user
    user_id = (params[:user_id] if params[:user_id].present?) || session[:user_id].to_s
    @user = User.find_by(id: user_id)
    @countries = Country.all
  end

  def user_profile_params
    params.require(:user).permit(:age, :salutation, :fullname, :designation, :employee_id, :dob, :gender, :mobilenumber, :telephone, :registration_number, :address, :city, :state, :pincode, :user_profile_pic, :qualification, :fellowship)
  end

  def user_signature_params
    params.require(:user).permit(:digital_signature, :user_signature, :include_designation, :include_registration_number, :include_specialty, :include_qualification, :include_fellowship, :include_print_datetime)
  end

  # Convert data uri to uploaded file. Expects object hash, eg: params[:post]
  def convert_data_uri_to_upload(obj_hash)
    if obj_hash.try(:match, %r{^data:(.*?);(.*?),(.*)$})
      image_data = split_base64(obj_hash)
      image_data_string = image_data[:data]
      image_data_binary = Base64.decode64(image_data_string)

      temp_img_file = Tempfile.new("data_uri-upload")
      temp_img_file.binmode
      temp_img_file << image_data_binary
      temp_img_file.rewind

      img_params = { :filename => "data-uri-img.#{image_data[:extension]}", :type => image_data[:type], :tempfile => temp_img_file }
      uploaded_file = ActionDispatch::Http::UploadedFile.new(img_params)

      obj_hash = uploaded_file
    end

    return obj_hash
  end

  # Split up a data uri
  def split_base64(uri_str)
    if uri_str.match(%r{^data:(.*?);(.*?),(.*)$})
      uri = Hash.new
      uri[:type] = $1 # "image/gif"
      uri[:encoder] = $2 # "base64"
      uri[:data] = $3 # data string
      uri[:extension] = $1.split('/')[1] # "gif"
      return uri
    else
      return nil
    end
  end
end
