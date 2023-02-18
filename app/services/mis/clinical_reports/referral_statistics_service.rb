# rubocop:disable all
module Mis::ClinicalReports
  class ReferralStatisticsService
    class << self
      def call(mis_params, request = 'json')
        @mis_params = mis_params
        @request = request
        @data_array = []

        unless @request == 'json'
          @data_array << Mis::Constants::ReportSheetFilters.filters_array(@mis_params)
        end

        lists = MisClinical::Opd::PatientReferralStats.collection.aggregate(opd_stats_query).to_a || []
        total_records = unless @request == 'json'
                          @stats_lists = lists || []
                          0
                        else
                          @stats_lists = lists[0][:data] || []
                          lists[0][:metadata].present? ? lists[0][:metadata][0][:total] : 0
                        end
        opd_list_data
        [@data_array, total_records]
      end

      private

      def opd_list_data
        @stats_lists.try(:each) do |opd_list|
          created_date = opd_list[:_id].strftime('%d/%m/%Y')
          appointment_date = opd_list[:_id].strftime('%d/%m/%Y')
          referral = opd_list[:opd_list].group_by { |val| val[:referral_type_id] }
          referral.each do |key, stats|
            ref_name = key.present? ? stats[0][:referral_name] : '----'
            new = stats[0][:patient_type_stats_fields][:new]
            follow_up = stats[0][:patient_type_stats_fields][:follow_up]
            post_op = stats[0][:patient_type_stats_fields][:post_op]
            walkin = stats[0][:appointment_type_stats_fields][:walkin]
            appointment = stats[0][:appointment_type_stats_fields][:appointment]
            male = stats[0][:gender_stats_fields][:male]
            female = stats[0][:gender_stats_fields][:female]
            transgender = stats[0][:gender_stats_fields][:transgender]
            undefined_sex = stats[0][:gender_stats_fields][:undefined]
            till_twenty = stats[0][:age_stats_fields][:till_twenty]
            above_twenty_till_forty = stats[0][:age_stats_fields][:above_twenty_till_forty]
            above_forty_till_sixty = stats[0][:age_stats_fields][:above_forty_till_sixty]
            above_sixty_till_eighty = stats[0][:age_stats_fields][:above_sixty_till_eighty]
            above_eighty = stats[0][:age_stats_fields][:above_eighty]
            undefined = stats[0][:age_stats_fields][:undefined]
            total_count = till_twenty + above_twenty_till_forty + above_forty_till_sixty + above_sixty_till_eighty + above_eighty + undefined

            if @request == 'json'
              referral_type_id = stats[0][:referral_type_id].present? ? stats[0][:referral_type_id] : nil
              href = @mis_params[:url] + forward_params(appointment_date) + back_params
              total_count = if total_count > 0
                              "<a href='#{href}&referral_type_id=#{referral_type_id}'data-remote='true'>#{total_count}</a>"
                            end
              male = if male > 0
                       "<a href='#{href}&gender_type=Male&referral_type_id=#{referral_type_id}'data-remote='true'>#{male}</a>"
                     else
                       '__'
                     end
              female = if female > 0
                         "<a href='#{href}&gender_type=Female&referral_type_id=#{referral_type_id}'data-remote='true'>#{female}</a>"
                       else
                         '__'
                       end
              transgender = if transgender > 0
                              "<a href='#{href}&gender_type=Transgender&referral_type_id=#{referral_type_id}'data-remote='true'>#{transgender}</a>"
                            else
                              '__'
                            end
              undefined_sex =  if undefined_sex > 0
                                 "<a href='#{href}&gender_type=undefined&referral_type_id=#{referral_type_id}'data-remote='true'>#{undefined_sex}</a>"
                               else
                                 '__'
                               end

              till_twenty= if till_twenty > 0
                             "<a href='#{href}&initial_age=0&final_age=20&referral_type_id=#{referral_type_id}'data-remote='true'>#{till_twenty}</a>"
                             else
                             '__'
                           end
              above_twenty_till_forty = if above_twenty_till_forty > 0
                                          "<a href='#{href}&initial_age=21&final_age=40&referral_type_id=#{referral_type_id}'data-remote='true'> #{above_twenty_till_forty}</a>"
                                        else
                                          '__'
                                        end
              above_forty_till_sixty = if above_forty_till_sixty > 0
                                         "<a href='#{href}&initial_age=41&final_age=60&referral_type_id=#{referral_type_id}'data-remote='true'>#{above_forty_till_sixty}</a>"
                                       else
                                         '__'
                                       end
              above_sixty_till_eighty = if above_sixty_till_eighty > 0
                                          "<a href='#{href}&initial_age=61&final_age=80&referral_type_id=#{referral_type_id}' data-remote='true'>#{above_sixty_till_eighty}</a>"
                                        else
                                          '__'
                                        end

              above_eighty = if above_eighty > 0
                               "<a href='#{href}&initial_age=81&final_age=120&referral_type_id=#{referral_type_id}'data-remote='true'> #{above_eighty}</a>"
                             else
                               '__'
                             end
              undefined = if undefined > 0
                            "<a href='#{href}&initial_age=undefined&final_age=undefined&referral_type_id=#{referral_type_id}'data-remote='true'>#{undefined}</a>"
                            # TODO: -> in patient details page add filter for undefined
                          else
                            '__'
                          end
              new = if new > 0
                      "<a href='#{href}&patient_visit=New&referral_type_id=#{referral_type_id}'data-remote='true'>#{new}</a>"
                    else
                      '__'
                    end


              follow_up = if follow_up > 0
                            "<a href='#{href}&patient_visit=Followup&referral_type_id=#{referral_type_id}'data-remote='true'>#{follow_up}</a>"
                          else
                            '__'
                          end
              post_op = if post_op > 0
                          "<a href='#{href}&patient_visit=Post Op&referral_type_id=#{referral_type_id}'data-remote='true'>#{post_op}</a>"
                        else
                          '__'
                        end

              walkin = if walkin > 0
                         "<a href='#{href}&appointmenttype=walkin&referral_type_id=#{referral_type_id}'data-remote='true'>#{walkin}</a>"
                       else
                         '__'
                       end

              appointment = if appointment > 0
                              "<a href='#{href}&appointmenttype=appointment&referral_type_id=#{referral_type_id}' data-remote='true'>#{appointment}</a>"
                            else
                              '__'
                            end

            end

            @data_array << [created_date, "#{ref_name} (#{total_count})", till_twenty, above_twenty_till_forty, above_forty_till_sixty,
                            above_sixty_till_eighty, above_eighty, undefined, male, female, transgender, undefined_sex,
                            new, follow_up, post_op, walkin, appointment]
            created_date = ''
          end
        end
      end

      def forward_params(appointment_date)
        start_date = "&start_date=#{appointment_date}"
        end_date = "&end_date=#{appointment_date}"
        time_period = "&time_period=#{@mis_params[:time_period]}"
        organisation_id = "&organisation_id=#{@mis_params[:organisation_id]}"
        facility_id = "&facility_id=#{@mis_params[:facility_id]}"
        facility_name = "&facility_name=#{@mis_params[:facility_name].tr("'", '`')}"
        group = '&group=outpatient'
        title = '&title=patient_detail'
        has_params = '&has_params=true'
        initial_age = "&initial_age=#{@mis_params[:initial_age]}"
        final_age = "&final_age=#{@mis_params[:final_age]}"
        gender_type = "&gender_type=#{@mis_params[:gender_type]}"
        appointmenttype = "&appointmenttype=#{@mis_params[:appointmenttype]}"

        start_date + end_date + time_period + organisation_id + facility_id + facility_name + group + title +
          has_params + initial_age + final_age + gender_type + appointmenttype
      end

      def back_params
        back_start_date = "&back_start_date=#{@mis_params[:start_date]}"
        back_end_date = "&back_end_date=#{@mis_params[:end_date]}"
        back_time_period = "&back_time_period=Custom"
        back_group = "&back_group=#{@mis_params[:group]}"
        back_title = "&back_title=#{@mis_params[:title]}"
        back_skip = "&back_iDisplayStart=#{@mis_params[:iDisplayStart]}"
        back_length = "&back_iDisplayLength=#{@mis_params[:iDisplayLength]}"
        has_params = '&has_params=true'
        initial_age = "&initial_age=#{@mis_params[:initial_age]}"
        final_age = "&final_age=#{@mis_params[:final_age]}"
        gender_type = "&gender_type=#{@mis_params[:gender_type]}"
        appointmenttype = "&appointmenttype=#{@mis_params[:appointmenttype]}"

        back_start_date + back_end_date + back_time_period + back_group + back_title + back_skip + back_length +
          has_params + initial_age + final_age + gender_type + appointmenttype
      end

      def opd_stats_query
        Mis::ClinicalService::ReferralQueryBuilder.call(@mis_params, @request)
      end
    end
  end
end
