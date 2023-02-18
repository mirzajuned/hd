json.status @message
json.patient_referral_type @patient_referral_type
json.referral_type @patient_referral_type.try(:referral_type)
json.sub_referral_type @patient_referral_type.try(:sub_referral_type)
json.deleted_patient_referral_type @deleted_patient_referral_type
