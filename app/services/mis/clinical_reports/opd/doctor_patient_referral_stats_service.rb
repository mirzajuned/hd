module Mis::ClinicalReports::Opd
  class DoctorPatientReferralStatsService
    class << self
      def call(filtered_referral_summaries, referral_date, organisation_ids)
        group_by_organisations = filtered_referral_summaries.group_by { |al| al[:organisation_id] }
        group_by_organisations.each do |organisation_id, group_by_organisation|
          @organisation_id = organisation_id
          group_by_facilities = group_by_organisation.group_by { |al| al[:facility_id] }
          group_by_facilities.each do |facility_id, group_by_facility|
            @facility_id = facility_id
            @facility_name = Facility.find_by(id: @facility_id).try(:name)
            referral_summaries = group_by_facility.select do |referral_summary|
              referral_summary[:referred_on_date].to_date == referral_date
            end

            if referral_summaries && referral_summaries.count > 0
              date_wise_referral_summaries = referral_summaries.group_by { |i| i[:referred_on_date].to_date }
              stats_by_date(date_wise_referral_summaries)
            end
          end
        end
      end
      # end call method

      def stats_by_date(date_wise_referral_summaries)
        date_wise_referral_summaries.each do |referred_date, date_wise_referrals|
          doctor_wise_summaries = date_wise_referrals.group_by do |date_wise_referral|
            date_wise_referral[:from_doctor_id]
          end
          doctor_wise_stats(doctor_wise_summaries, referred_date)
          # EOF revenue statistics by department
        end
        # end date_wise_referral_summaries loop
      end
      # end stats_by_date(date_wise_referral_summaries) method

      def doctor_wise_stats(doctor_wise_summaries, referred_date)
        doctor_wise_summaries.each do |doctor_id, d_summaries|
          if doctor_id.present?
            doctor = User.find_by(id: doctor_id)
            doctor_name = doctor.try(:fullname)

            inter_facilities = d_summaries.select do |d_summary|
              d_summary[:referral_type_id] == 272440001 #Global.ehrcommon
            end
            intra_facilities = d_summaries.select do |d_summary|
              d_summary[:referral_type_id] == 272441002 #Global.ehrcommon
            end
            outside_organisations = d_summaries.select do |d_summary|
              d_summary[:referral_type_id] == 261074009 #Global.ehrcommon
            end

            referral_stats = MisClinical::Opd::DoctorPatientReferralStats.find_or_create_by(
              referred_date: referred_date, facility_id: @facility_id, doctor_id: doctor_id
            )

            referral_stats.organisation_id = @organisation_id
            referral_stats.facility_name = @facility_name
            referral_stats.doctor_name = doctor_name
            referral_stats.intra_facility_count = intra_facilities.count
            referral_stats.inter_facility_count = inter_facilities.count
            referral_stats.outside_organisation_count = outside_organisations.count

            referral_stats.save!
          end
        end
        # end doctor_wise_invoices loop
      end
      # end doctor_wise_stats method
    end
    # end self class
  end
  # end DoctorPatientReferralStatsService class
end
# end module