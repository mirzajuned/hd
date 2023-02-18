module Authorization::PolicyHelper
  def self.verification(current_user_id, policy_identifier, created_user_id = nil)
    user_policy = Authorization::UserPolicy.find_by(user_id: current_user_id)
    user_policies = user_policy.try(:policy_ids)

    auth_organisation_policy = Authorization::Policy.find_by(organisation_id: user_policy.try(:organisation_id), policy_identifier: policy_identifier, authorized: true)

    if auth_organisation_policy.present?
      if user_policies.include?(auth_organisation_policy.id.to_s)
        if auth_organisation_policy.maker_checker && current_user_id == created_user_id
          verification_result = false
        else
          verification_result = true
        end
      else
        verification_result = false
      end
    else
      # default
      auth_hg_policy = Authorization::HgPolicy.find_by(policy_identifier: policy_identifier, is_deleted: false)
      verification_result = auth_hg_policy ? auth_hg_policy.try(:default_value) : true
    end

    return verification_result
  end
end
