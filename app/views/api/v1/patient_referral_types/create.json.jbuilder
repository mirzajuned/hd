json.status @status
json.patient_referral_type @patient_referral_type
json.referral_type @patient_referral_type.try(:referral_type)
json.sub_referral_type @patient_referral_type.try(:sub_referral_type)
