module Api
  module V1
    class Inpatient::IpdRecord::OperativeNotesController < ApiApplicationController
      before_action :authorize_token
      before_action :find_ipd_record, only: [:new, :edit, :print, :show]
      before_action :convert_to_json, :find_ipd_record_for_write, only: [:create, :update]
      before_action :operative_note_form_params, only: [:new, :edit]
      before_action :operative_note, only: [:show, :edit, :print]
      before_action :operative_note_for_write, only: [:create, :update]
      before_action :procedure_form_data, only: [:new, :edit]
      before_action :clinical_note_data, only: [:new, :edit, :create, :update, :show, :print]

      def new
        @operative_note = @ipdrecord.operative_notes.new
        @operative_note_counter = @ipdrecord.operative_notes.size
        @diagnosislist = @ipdrecord.diagnosislist
        # @inventorymedication = @operative_note.inventorymedication.new
        @advice = @operative_note.build_advice
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/operative_note/#{@current_department}_notes"
        @method = "POST"
        # respond_to do |format|
        #   format.js { render "inpatient/ipd_record/operative_note/form" }
        # end
      end

      def create
        if params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:ot_note_procedures] == "0"
          respond_to do |format|
            format.js { render js: "if ($('.ui-pnotify').length > 0) { $('.ui-pnotify').remove() } notice = new PNotify({ title: 'Warning', text: 'Cannot create operative note without performed procedure', type: 'warning' }); notice.get().click(function(){ notice.remove() });" }
          end
        else
          if @ipdrecord.update(operative_note_params)
            # flash[:error] = @ipdrecord.errors.full_messages.to_sentence
            @operative_note = @ipdrecord.operative_notes[-1]
            @operative_note.record_histories.create(user_id: current_user.id, action: "C", actiontime: Time.current, template_type: "Operative Note")
            update_operative_note_id_in_procedure
            time_calculation
            operative_note_view_params
            # save_procedures
            # render json: {'success': true}
            Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "CREATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Operative Note", note_id: @operative_note.id })
            IpdRecordJob.perform_later(@ipdrecord.id.to_s, @operative_note.id.to_s, 'operative_note')
          end
        end
      end

      def show
        operative_note_view_params
        respond_to do |format|
          format.js { render "inpatient/ipd_record/operative_note/show" }
        end
      end

      def edit
        @current_department = current_user.department.name.downcase
        @url = "/inpatient/ipd_record/operative_note/#{@current_department}_notes/#{@ipdrecord.id}"
        @method = "PATCH"
        # respond_to do |format|
        #   format.js { render "inpatient/ipd_record/operative_note/form" }
        # end
      end

      def update
        if params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:ot_note_procedures] == "0"

          render json: { 'success': false, 'msg': "Cannot create operative note without performed procedure" }

        else
          delete_inventory_data if current_user.department.name == "Orthopedics"
          if @ipdrecord.update_attributes(operative_note_update_params)
            @operative_note.record_histories.create(user_id: current_user.id, action: "U", actiontime: Time.current, template_type: "Operative Note")
            update_operative_note_id_in_procedure
            time_calculation
            operative_note_view_params
            # save_procedures

            Patients::Summary::TimelineWorker.call({ event_name: "IPD_RECORD", sub_event_name: "UPDATED", ipd_record_id: @ipdrecord.id, user_id: current_user.id, user_name: current_user.fullname, ipdtemplatetype: "Operative Note", note_id: @operative_note.id })
            IpdRecordJob.perform_later(@ipdrecord.id.to_s, @operative_note.id.to_s, 'operative_note')
          end
        end
      end

      def print
        @view = params[:view]

        @patient = Patient.find(@ipdrecord.patient_id)
        @admission = Admission.find(@ipdrecord.admission_id)
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @ipdrecord.admission_id)
        @department = current_user.department.name.downcase
        @organisation = current_user.organisation
        setting_service = PrintSettingService.new(current_facility_id, @admission.doctor.to_s, "IPD")
        @print_settings = setting_service.select_print_setting
        @logo = @print_settings[1]
        respond_to do |format|
          format.pdf { render :template => "inpatient/ipd_record/operative_note/print", :pdf => "", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 10, :html => { :template => 'layouts/pdf-header.html' } }, :footer => { :html => { :template => 'layouts/pdf-footer.html' }, :spacing => 10, }, :margin => { :top => @print_settings[0]['header_height'].to_f * 10, :bottom => 40 } }
        end
        # Patients::Summary::TimelineWorker.call({event_name: "IPD_RECORD", sub_event_name: "PRINTED", ipd_record_id: @operative_note.id, user_id: current_user.id, user_name: current_user.fullname })
      end

      private

      def operative_note_form_params
        current_user = User.find(params[:current_user_id])
        @current_facility = current_facility
        @admission = Admission.find_by(id: params[:admission_id])
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
        @patient = @admission.patient
        @patient_identifier_id = @patient.patient_identifier_id
        @patient_mrn = @patient.patient_mrn
        @age_gender = @patient.patient_age_gender
        @advice_set = AdviceSet.where(organisation_id: current_user.organisation_id, is_deleted: false, '$or' => [
                                        { level: "organisation" },
                                        { facility_id: current_facility.id, level: "facility" },
                                        { user_id: current_user.id, level: "user" }
                                      ]).order(counter: "desc").map { |p| ["#{p[:name]} by: #{p[:level].to_s.capitalize}", p.language_advice_subset[0][:content], "#{p[:id]}"] } + Global.ophthal_advice_option.sets.map { |p| ["#{p[:name]}", "#{p[:content]}", "#{p[:id]}"] }
        @procedurenotes_set = ProcedureNote.where(:organisation_id => current_user.organisation_id.to_s, is_active: true, '$or' => [{ level: 'organisation' }, { facility_id: current_facility.id, level: 'facility' }, { user_id: current_user.id, level: 'user' }]).map { |p| ["#{p[:name]}", "#{p[:proceduretext].to_s.html_safe.to_s}"] }
      end

      def operative_note_view_params
        @admission = Admission.find_by(id: @ipdrecord.admission_id)
        @patient = Patient.find_by(id: @ipdrecord.patient_id)
        @tpa = ::Inpatient::Insurance::Tpa.find_by(admission_id: @admission.id)
        if @operative_note.advice.advice_set_id.present? && @operative_note.advice.advice_set_id.length > 2
          @advice_data = AdviceSet.find_by(id: @operative_note.advice.advice_set_id).language_advice_subset
        end
      end

      def operative_note_params
        params.require(:inpatient_ipd_record).permit(operative_notes_attributes: [:note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :correct_patient, :correct_procedure, :before_induction_valid_consent, :site_marked, :anesthesia_machine, :tourniquet_drills_suction, :implants_checked, :patient_allergy, :difficult_airway, :confirm_team_listed, :patient_checked, :valid_consent, :procedure_checked, :site_checked_and_marked, :imaging_checked, :antibiotic_prophylaxis_given, :xray_safety_check, :otchecklist_comments, :irrigation_solution, :irrigation_solution_batch_no, :sutures, :sutures_batch_no, :viscoelastic, :viscoelastic_batch_no, :trypan_blue, :trypan_blue_batch_no, :other_consumables, :implants, :power_inventory, :surgeon, :surgeon1, :surgeon2, :surgeon3, :surgeon_assistant, :surgeon_assistant1, :surgeon_assistant2, :surgeon_assistant3, :anaesthetist, :anaesthetist1, :anaesthetist2, :anaesthetist3, :anesthetic_assistant, :anesthetic_assistant1, :anesthetic_assistant2, :anesthetic_assistant3, :circulating_nurse, :circulating_nurse1, :circulating_nurse2, :circulating_nurse3, :scrub_nurse, :scrub_nurse1, :scrub_nurse2, :scrub_nurse3, :other_staff, :other_staff1, :other_staff2, :other_staff3, :personnel_comments, :surgerytype, :anesthesia, :diagnosis, :procedure_performed, :patient_entry_time, :patient_exit_time, :anesthesia_start_time, :anesthesia_end_time, :surgery_start_time, :surgery_end_time, :complication, :complication_comment, :implants_used, :post_op_plan, :procedure_note, :patient_position, :position_aid, :bed_attachments, :other_equipments, :skin_preparation, :theatre_diathermy, :diathermy_type, :diathermy_plate_site, :diathermy_applier, :theatre_tourniquet, :tourniquet_site, :tourniquet_pressure, :tourniquet_time, :theatre_biopsy, :biopsy_type, :biopsy_tests, :catheters_insitu, :closure, :theatre_comments, :ot_note_inventory_comments, :surgerydate, ot_note_procedures: [], inventorymedication_attributes: inventory_create_attributes, inventoryconsumables_attributes: inventory_create_attributes, inventorypack_attributes: inventory_create_attributes, inventoryprep_attributes: inventory_create_attributes, inventorydressings_attributes: inventory_create_attributes, inventoryinstrument_attributes: inventory_create_attributes, inventoryimplants_attributes: inventory_create_attributes, inventoryswabs_attributes: inventory_create_attributes, advice_attributes: [:advice_content, :advice_set_id]], procedure_attributes: [:id, :procedure_type, :procedurestage, :procedurename, :procedure_id, :procedure_performed, :procedureside, :procedurefullcode, :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :procedure_comment, :users_comment, :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id, :performed_by, :performed_by_id, :performed_at_facility, :performed_at_facility_id, :performed_datetime, :operative_note_id, :_destroy])
      end

      def operative_note_update_params
        params.require(:inpatient_ipd_record).permit(operative_notes_attributes: [:id, :note_date, :note_time, :note_created_at, :organisation_id, :admission_id, :patient_id, :user_id, :department, :specalityname, :specalityid, :ward_id, :room_id, :bed_id, :daycare, :patient_name, :patient_age, :patient_gender, :mr_no, :patient_identifier_id, :correct_patient, :correct_procedure, :before_induction_valid_consent, :site_marked, :anesthesia_machine, :tourniquet_drills_suction, :implants_checked, :patient_allergy, :difficult_airway, :confirm_team_listed, :patient_checked, :valid_consent, :procedure_checked, :site_checked_and_marked, :imaging_checked, :antibiotic_prophylaxis_given, :xray_safety_check, :otchecklist_comments, :irrigation_solution, :irrigation_solution_batch_no, :sutures, :sutures_batch_no, :viscoelastic, :viscoelastic_batch_no, :trypan_blue, :trypan_blue_batch_no, :other_consumables, :implants, :power_inventory, :surgeon, :surgeon1, :surgeon2, :surgeon3, :surgeon_assistant, :surgeon_assistant1, :surgeon_assistant2, :surgeon_assistant3, :anaesthetist, :anaesthetist1, :anaesthetist2, :anaesthetist3, :anesthetic_assistant, :anesthetic_assistant1, :anesthetic_assistant2, :anesthetic_assistant3, :circulating_nurse, :circulating_nurse1, :circulating_nurse2, :circulating_nurse3, :scrub_nurse, :scrub_nurse1, :scrub_nurse2, :scrub_nurse3, :other_staff, :other_staff1, :other_staff2, :other_staff3, :personnel_comments, :surgerytype, :anesthesia, :diagnosis, :procedure_performed, :patient_entry_time, :patient_exit_time, :anesthesia_start_time, :anesthesia_end_time, :surgery_start_time, :surgery_end_time, :complication, :complication_comment, :implants_used, :post_op_plan, :procedure_note, :patient_position, :position_aid, :bed_attachments, :other_equipments, :skin_preparation, :theatre_diathermy, :diathermy_type, :diathermy_plate_site, :diathermy_applier, :theatre_tourniquet, :tourniquet_site, :tourniquet_pressure, :tourniquet_time, :theatre_biopsy, :biopsy_type, :biopsy_tests, :catheters_insitu, :closure, :theatre_comments, :surgerydate, :ot_note_inventory_comments, ot_note_procedures: [], inventorymedication_attributes: inventory_create_attributes, inventoryconsumables_attributes: inventory_create_attributes, inventorypack_attributes: inventory_create_attributes, inventoryprep_attributes: inventory_create_attributes, inventorydressings_attributes: inventory_create_attributes, inventoryinstrument_attributes: inventory_create_attributes, inventoryimplants_attributes: inventory_create_attributes, inventoryswabs_attributes: inventory_create_attributes, advice_attributes: [:id, :advice_content, :advice_set_id]], procedure_attributes: [:id, :procedurestage, :procedure_type, :procedurename, :procedure_id, :procedure_performed, :procedureside, :procedurefullcode, :entered_by, :entered_by_id, :entered_at_facility, :entered_at_facility_id, :procedure_comment, :users_comment, :entered_datetime, :updated_datetime, :updated_by, :updated_by_id, :updated_at_facility, :updated_at_facility_id, :performed_by, :performed_by_id, :performed_at_facility, :performed_at_facility_id, :performed_datetime, :operative_note_id, :_destroy])
      end

      def inventory_create_attributes
        [:name, :quantity, :used, :remaining]
      end

      def procedure_attributes
        params.require(:inpatient_ipd_record).permit(procedure_attributes: [:_id, :procedurename, :procedurestage, :procedureside, :surgerydate, :procedure_type])
      end

      def clinical_note_data
        @clinical_note = @ipdrecord.clinical_note
        @diagnosislist = @ipdrecord.diagnosislist
      end

      def procedure_form_data
        @procedure = @ipdrecord.procedure.where(:operative_note_id.in => [nil, "", @operative_note.try(:id)])
      end

      def operative_note
        @operative_note = @ipdrecord.operative_notes.find_by(id: params[:id])
      end

      def operative_note_for_write
        @operative_note = @ipdrecord.operative_notes.find_by(id: params[:inpatient_ipd_record][:operative_notes_attributes]["0"][:id])
      end

      def delete_inventory_data
        @operative_note.inventorymedication.delete_all
        @operative_note.inventoryconsumables.delete_all
        @operative_note.inventorypack.delete_all
        @operative_note.inventoryprep.delete_all
        @operative_note.inventorydressings.delete_all
        @operative_note.inventoryinstrument.delete_all
        @operative_note.inventoryimplants.delete_all
        @operative_note.inventoryswabs.delete_all
      end

      def time_calculation
        if @operative_note.patient_entry_time.present? && @operative_note.patient_exit_time.present?
          time_total_sec = @operative_note.patient_exit_time - @operative_note.patient_entry_time
          time_in_hours = (((time_total_sec) / 60) / 60).to_i
          time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
          time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
          @operative_note.update_attributes(patient_entry_exit_time: time_to_save)
        end

        if @operative_note.anesthesia_start_time.present? && @operative_note.anesthesia_end_time.present?
          time_total_sec = @operative_note.anesthesia_end_time - @operative_note.anesthesia_start_time
          time_in_hours = (((time_total_sec) / 60) / 60).to_i
          time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
          time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
          @operative_note.update_attributes(anesthesia_start_end_time: time_to_save)
        end

        if @operative_note.surgery_start_time.present? && @operative_note.surgery_end_time.present?
          time_total_sec = @operative_note.surgery_end_time - @operative_note.surgery_start_time
          time_in_hours = (((time_total_sec) / 60) / 60).to_i
          time_in_minutes = (((time_total_sec) / 60).to_i) - (time_in_hours * 60)
          time_in_seconds = time_total_sec - ((((time_total_sec) / 60).to_i) * 60)
          time_to_save = time_in_hours.abs.to_s + "h " + time_in_minutes.abs.to_s + "m " + time_in_seconds.round.abs.to_s + "s"
          @operative_note.update_attributes(surgery_start_end_time: time_to_save)
        end
      end

      # def save_procedures
      #   recomended_procedure = params[:procedure]
      #   if recomended_procedure
      #     recomended_procedure.each_with_index do |proc|
      #       @procedure = Inpatient::Procedure.find_by(id: proc[1]["id"])
      #       if proc[1]["status"] == "Pre-Operative"
      #         @procedure.update_attributes(procedurestatus: "Pre-Operative", surgerydate: proc[1]["surgerydate"], procedureside: proc[1]["side"])
      #       elsif proc[1]["status"] == "Performed"
      #         @procedure.update_attributes(procedurestatus: "Performed", surgerydate: proc[1]["surgerydate"], procedureside: proc[1]["side"])
      #       elsif proc[1]["status"].nil?
      #         @procedure.update_attributes(procedurestatus: "Advised", procedureside: proc[1]["side"])
      #       end
      #     end
      #   end
      # end

      def find_ipd_record
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:admission_id])
      end

      def find_ipd_record_for_write
        @ipdrecord = ::Inpatient::IpdRecord.find_by(admission_id: params[:inpatient_ipd_record][:admission_id])
      end

      def convert_to_json
        params[:inpatient_ipd_record] = eval(params[:inpatient_ipd_record])
        # params[:inpatient_ipd_record] = JSON.parse(params[:inpatient_ipd_record].gsub(/:(\w+)/){"\"#{$1}\""}.gsub('=>', ':'))
        # params[:patient] = eval(params[:patient])
      end

      def update_operative_note_id_in_procedure
        @ipdrecord.procedure.each do |proc|
          if proc.procedurestage == "P" and proc.operative_note_id.blank?
            proc.update(operative_note_id: @operative_note.id)
          end
        end
      end
    end
  end
end
