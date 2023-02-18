class ReferralCodesController < ApplicationController
  def validate_code
    referral_code = ReferralCode.find_by(code: params[:code])
    if referral_code.present?
      if referral_code.code_expiry_date > Date.current
        expiry = (Date.current + referral_code.free_trial_period.to_i.days).strftime('%d/%m/%Y')
        message, color = referral_code.success_message
      else
        expiry = (Date.current + 30.days).strftime('%d/%m/%Y')
        message, color = referral_code.failure_message
      end
    end
    respond_to do |format|
      format.json { render :json => { expiry: expiry, message: message, color: color } }
    end
  end
end
