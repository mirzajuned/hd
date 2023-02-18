module Api
  module V1
    class PasswordResetsController < ApiApplicationController
      def verification
        password_reset = PasswordReset.user_verification(params)
        if password_reset.try(:user)
          password_reset.send_email
          user_token = password_reset.user.password_reset_token
          user_id =  password_reset.user.id.to_s
          UserMailer.password_reset(password_reset).deliver_now
          render json: { result: true, reset_token: password_reset.user.password_reset_token, user_id: user_id }
        else
          render json: { result: false, error: "Incorrect Username/Email" }
        end
      end

      def change
        password_reset = PasswordReset.from_token(params[:reset])
        if password_reset.user.nil?
          render json: { result: false, message: "Password reset token is invalid." }
        elsif password_reset.expired?
          render json: { result: false, message: "Password reset token has expired." }
        else
          @user = password_reset.user
          render json: { result: true, user_id: @user.id.to_s }
        end
      end

      def update
        @user = User.find(params[:user][:id])
        @user.password = params[:user][:password]
        @user.password_reset_token = ''
        @user.password_reset_sent_at = ''
        @user.upsert
        render json: { result: true, message: "Password successfully changed." }
      end
    end
  end
end
