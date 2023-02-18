module Mis::ClinicalReports::Opd
  class DeleteDoctorPatientReferralSummaryService
    class << self
      def call(record_id)
        opd_record = OpdRecord.find_by(id: record_id)
        if opd_record.present?
          # referral_id = inter_facility/intra_facility/outside_organisation model id
          # referral_type_id = inter_facility=272440001/intra_facility=272441002/outside_organisation=261074009
          # remove deleted inter facilities:
          inter_facility_ids = opd_record.inter_facility_referral.pluck(:id)
          MisClinical::Opd::DoctorPatientReferralSummaryReport.where(
            primary_model_id: record_id, referral_type_id: 272440001,
            :referral_id.nin => inter_facility_ids
          ).destroy_all
          
          # remove deleted intra facilities:
          intra_facility_ids = opd_record.intra_facility_referral.pluck(:id)
          MisClinical::Opd::DoctorPatientReferralSummaryReport.where(
            primary_model_id: record_id, referral_type_id: 272441002,
            :referral_id.nin => intra_facility_ids
          ).destroy_all

          # remove deleted outside org:
          outside_ids = opd_record.outside_organisation_referral.pluck(:id)
          MisClinical::Opd::DoctorPatientReferralSummaryReport.where(
            primary_model_id: record_id, referral_type_id: 261074009,
            :referral_id.nin => outside_ids
          ).destroy_all
        end
      end
    end
  end
end
