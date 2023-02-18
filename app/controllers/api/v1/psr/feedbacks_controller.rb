module Api
  module V1
    module Psr
      class FeedbacksController < ApiApplicationController
        before_action :doorkeeper_authorize!

        def create
          params[:data] = eval(params[:data])
          # params[:data] = JSON.parse(params[:data].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
          if params[:qr_auth_token].present?
            @link_device = LinkFacilityDevice.find_by(qr_auth_token: params[:qr_auth_token])
            user_id = @link_device.user_id.to_s
            @link_device.update(last_activity_date: DateTime.current)
            params[:data][:user_id] = user_id
            params[:data][:facility_id] = params[:current_facility_id]
            params[:data][:organisation_id] = params[:organisation_id]

            # ========================>rating logic start
            total_count = 0
            total_rating = 0
            rating_array = [params[:data][:rating1].to_f, params[:data][:rating2].to_f, params[:data][:rating3].to_f, params[:data][:rating4].to_f, params[:data][:rating5].to_f, params[:data][:rating6].to_f, params[:data][:rating7].to_f, params[:data][:referral_rating].to_f]
            rating_array.each do |rating|
              if rating.present?
                total_rating = total_rating + rating
                total_count = total_count + 1
              end
            end
            avg_rating = total_rating / total_count
            params[:data][:average_rating] = avg_rating.to_f
            # ========================>rating logic ends

            if params[:data][:patient_id].present?
              params[:data][:is_patient] = true

              patient = Patient.find_by(id: params[:data][:patient_id])

              if patient.present?

                pat_feedback = Feedback.collection.aggregate([{ "$match" => { "patient_id" => patient.id } }, { "$group" => { "_id" => "$patient_id", "total_rating" => { "$sum" => "$average_rating" }, "count" => { "$sum" => 1 } } }]).to_a[0]

                if pat_feedback.present?
                  patient_avg_rating = (pat_feedback["total_rating"] + avg_rating.to_f) / (pat_feedback["count"] + 1)
                  patient.update(rating: patient_avg_rating.to_f)
                else
                  patient.update(rating: avg_rating.to_f)
                end

                params[:data][:salutation] = patient.try(:salutation)
                params[:data][:fullname] = patient.try(:fullname)
                params[:data][:mobilenumber] = patient.try(:mobilenumber)
                params[:data][:email] = patient.try(:email)
                params[:data][:address_1] = patient.try(:address_1)
                params[:data][:address_2] = patient.try(:address_2)
                params[:data][:age] = patient.try(:age)
                params[:data][:dobyear] = patient.try(:dobyear)
                params[:data][:city] = patient.try(:city)
                params[:data][:state] = patient.try(:state)
              end

            end

            @feedback = Feedback.new(feedback_params)

            if @feedback.save
              @message = "Success"
            else
              @message = "Failed"
            end
          else
            @message = "User Id is not present"
          end
          respond_to do |format|
            format.json {}
          end
        end

        private

        def feedback_params
          params.require(:data).permit(:salutation, :fullname, :mobilenumber, :email, :address_1, :address_2, :age, :dobyear, :city, :state, :rating1, :rating2, :rating3, :rating4, :rating5, :rating6, :rating7, :referral_rating, :referral_rating_comment, :average_rating, :feedback_note, :type, :is_patient, :patient_id, :facility_id, :user_id, :organisation_id)
        end
      end
    end
  end
end
