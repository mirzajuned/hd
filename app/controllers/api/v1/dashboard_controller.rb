module Api
  module V1
    class DashboardController < ApiApplicationController
      before_action :authorize_token

      api :GET, "/api/v1/dashboard/stats", "Get dashboard stats on mobile and tablet."
      formats ['json']
      description <<-EOS
          == Get dashboard stats on mobile and tablet
             URL: /api/v1/dashboard/stats
             JSON format to get dashboard data. Ex json: { today_date: "06/05/2016", facility_id: "3333333333333" }
      EOS
      def stats
        # @current_date = "#{Date.strptime("#{params[:today_date]}", "%d/%m/%Y").strftime('%Y-%m-%d')}"
        @facility = Facility.find_by(:id => params[:facility_id].to_s)

        #### OPD Stats
        @fac_date = Appointment.where(:appointmentdate => Date.current, :facility_id => @facility.id.to_s)
        @scheduled_patient_doctor = @fac_date.where(:arrived => false, :appointmentstatus => 416774000).count
        @patient_arrived_doctor = @fac_date.where(:arrived => true, :seen => false, :engaged => false, :appointmentstatus => 416774000).count
        @patient_seen_doctor = @fac_date.where(:seen => true, :appointmentstatus => 416774000).count
        @cancelled_patient_doctor = @fac_date.where(:appointmentstatus => 89925002).count

        #### IPD Stats
        @admission_today_doctor = Admission.where(:admissiondate => Date.current, :facility_id => @facility.id.to_s).count
        @patients_ot_doctor = OtSchedule.where(:otdate => Date.current, :facility_id => @facility.id.to_s).count
        @admitted_patient_doctor = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => false).count
        @discharged_today_doctor = Admission.where(:facility_id => @facility.id.to_s, :isdischarged => true, :dischargedate => Date.current).count

        respond_to do |format|
          format.json { render "dashboard_stats", :layout => false }
        end
      end

      api :GET, "/api/v1/dashboard/get_dashboard_for_date", "Get dashboard data on mobile and tablet"
      formats ['json']
      description <<-EOS
          == Get dashboard data on mobile and tablet
             URL: /api/v1/dashboard/get_dashboard_for_date
             JSON format to get dashboard data. Ex json: { dashboard: { todaydate: "06/05/2015" } }
      EOS
      def get_dashboard_for_date
        respond_to do |format|
          format.json { render "get_dashboard_for_date", :layout => false }
        end
      end

      def get_opd_appointment_count_for_date
      end

      def get_ot_count_for_date
      end

      def get_admission_count_for_date
      end

      def get_discharge_count_for_date
      end
    end
  end
end
