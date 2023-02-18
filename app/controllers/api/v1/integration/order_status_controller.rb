module Api
  module V1
    module Integration
      class OrderStatusController < ApiApplicationController
        before_action :doorkeeper_authorize!
        after_action :create_data_request, :create_data_response
        respond_to :json

        #     {"appointment_integration_identifier"=>"SEHIND-1582259", "mr_no"=>"SECIND/001639/20", "facility_integration_identifier"=>"5e14310e19e7da18be14b65b", "organisation_integration_identifier"=>"5e14310e19e7da18be14b65c", "investigations"=>[<ActionController::Parameters {"id"=>4365607, "status"=>"BILLED", "code"=>"LAB009"} permitted: false>], "procedures"=>[], "medicines"=>[], "format"=>"json", "controller"=>"api/v1/integration/order_status", "action"=>"update", "order_status"=>{"appointment_integration_identifier"=>"SEHIND-1582259", "mr_no"=>"SECIND/001639/20", "facility_integration_identifier"=>"5e14310e19e7da18be14b65b", "organisation_integration_identifier"=>"5e14310e19e7da18be14b65c", "investigations"=>[{"id"=>4365607, "status"=>"BILLED", "code"=>"LAB009"}], "procedures"=>[], "medicines"=>[]}}

        def update
          @original_params = params.dup
          params_received

          Rails.logger.info("==========================order status params===========================> #{params}")

          puts '======================================================order status param======================================>', params

          find_organisation
          find_facility
          find_appointment_data
          find_appointment
          find_order

          puts '======================================================all params done======================================>'
          Rails.logger.info("==========================all params done===========================> #{params}")

          begin
            if @order_data.present?

              puts '======================================================order_data present======================================>'
              Rails.logger.info("==========================order_data present===========================>#{@order_data}")

              placed_order_data = @order_data.data

              Rails.logger.info("==========================placed_order_data===========================> #{placed_order_data}")
              Rails.logger.info("==========================placed_order_data==inspect=========================> #{placed_order_data.inspect}")

              if @investigation_params.present?
                puts '======================================================update_investigation_status======================================>'
                updated_investigation_order = update_investigation_status(@appointment.id, placed_order_data['investigationOrders'], @appointment.patient_id)
                puts '======================================================update_investigation_status======================================>', updated_investigation_order
                Rails.logger.info("==========================updated_investigation_order===========================> #{updated_investigation_order}")
              end

              if @procedure_params.present?
                puts '======================================================updated_procedure_order======================================>'
                updated_procedure_order = update_procedure_status(@appointment.id, placed_order_data['procedureAdvices'])
                puts '======================================================updated_procedure_order======================================>', updated_procedure_order
                Rails.logger.info("==========================updated_procedure_order===========================> #{updated_procedure_order}")
              end

              if @medicine_params.present?
                puts '======================================================updated_medicine_order======================================>'
                updated_medicine_order = update_medicine_status(@appointment.id, placed_order_data['drugOrders'])
                puts '======================================================updated_medicine_order======================================>', updated_medicine_order
                Rails.logger.info("==========================updated_medicine_order===========================> #{updated_medicine_order}")
              end

              updated_order_data = placed_order_data

              updated_order_data['investigationOrders'] = updated_investigation_order || []

              updated_order_data['procedureAdvices'] = updated_procedure_order || placed_order_data["procedureAdvices"]

              updated_order_data['drugOrders'] = updated_medicine_order || placed_order_data["drugOrders"]

              puts '======================================================updated_order_data======================================>', updated_order_data
              Rails.logger.info("==========================updated_order_data===========================> #{updated_order_data}")

              @order_data.update!(data: updated_order_data)
            end

            @status_code = 200
            @msg = 'Successfully Updated'
            @status = 'Success'
            @response_data = { mr_no: @mr_no, facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier }
          rescue StandardError => e
            puts '======================================================error======================================>', e
            puts '======================================================error======================================>', e.backtrace
            Rails.logger.info("==========================e===========================> #{e}")
            Rails.logger.info("==========================error========backtrace===================> #{e.backtrace}")

            @status = 'Failed'
            @status_code = 500
            @msg = 'Data Not Updated'
            @response_data = { mr_no: @mr_no, facility_integration_identifier: @facility_integration_identifier, organisation_integration_identifier: @organisation_integration_identifier }
          end

          @message = { msg: @msg, status: @status, status_code: @status_code, data: @response_data }
        end

        private

        def params_received
          @facility_integration_identifier = params[:facility_integration_identifier]
          @appointment_integration_identifier = params[:appointment_integration_identifier]
          @organisation_integration_identifier = params[:organisation_integration_identifier]
          @mr_no = params[:mr_no].to_s.upcase.strip

          @investigation_params = params[:investigations]

          @procedure_params = params[:procedures]

          @medicine_params = params[:medicines]
        end

        def find_organisation
          @organisation = Organisation.find_by(integration_identifier: @organisation_integration_identifier)
        end

        def find_facility
          @facility = Facility.find_by(integration_identifier: @facility_integration_identifier, organisation_id: @organisation.id)
        end

        def find_appointment_data
          @appointment_data = ApiIntegration::Appointment::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier, registered_appointment: true, status_code: 200, method_type: 'Create')
        end

        def find_appointment
          if @patient.present? && @facility.present? && @appointment_data.nil? && params[:action] == 'create'
            appointment_date = (@appointment_date if @appointment_date.present?) || Date.current
            @appointment = Appointment.find_by(facility_id: @facility&.id.to_s, patient_id: @patient.try(:id).to_s, appointmentdate: appointment_date, appointmentstatus: 416774000)
          elsif @appointment_data.present? && params[:action] == 'update'
            @appointment = Appointment.find_by(integration_identifier: @appointment_data.appointment_integration_identifier_bson)
          end
        end

        def find_order
          @order_data = ApiIntegration::Order::Data.find_by(appointment_integration_identifier: @appointment_integration_identifier)
        end

        def update_investigation_status(appointment_id, placed_investigation_order, patient_id)
          if placed_investigation_order.present?

            Rails.logger.info("==========================@investigation_params===========================> #{placed_investigation_order}")

            updated_investigation_order = placed_investigation_order.each do |investigation|
              Rails.logger.info("==========================@investigation_params===========================> #{@investigation_params}")

              Rails.logger.info("==========================investigation===========================> #{investigation}")

              Rails.logger.info("==========================investigation['id']===========================> #{investigation['id']}")

              current_investigation = @investigation_params.find { |h| h['id'] == investigation['id'] }

              Rails.logger.info("==========================current_investigation===========================> #{current_investigation}")

              next unless current_investigation.present?

              Rails.logger.info("==========================current_investigation_present===========================> #{current_investigation}")

              current_investigation_status = current_investigation['status']

              investigation['status'] = current_investigation_status

              investigation['bill_number'] = current_investigation['billNumber']

              investigation['billed_date'] = current_investigation['billedDate']

              Rails.logger.info("==========================current_investigation_status===========================> #{current_investigation_status}")
              Rails.logger.info("==========================investigation===========================> #{investigation}")

              # updating the investigation records
              next unless current_investigation_status == 'BILLED'

              puts '======================================================BILLED======================================>', appointment_id, investigation['code']

              Rails.logger.info("==========================appointment_id===========investigation['code']================> #{appointment_id}, #{investigation['code']}")

              Rails.logger.info("==========================@investigation===========================> #{@investigation.inspect}")

              @investigations = Investigation::InvestigationDetail.where(patient_id: patient_id.to_s, appointment_id: appointment_id.to_s, investigation_id: investigation['code'], state: 'advised')
              if @investigations[0].try(:_type) == 'Investigation::Ophthal'
                @investigation = @investigations.find_by(investigation_side: investigation.try(:[], 'investigation_side'))
                @investigation = @investigations[0] if @investigation.blank?
              else
                @investigation = @investigations[0]
              end

              next unless @investigation.present?

              Rails.logger.info("==========================@investigation=present==========================> #{@investigation.inspect}, #{@investigation.id}")

              unless @investigation.update!(payment_done: true, collected_by: nil, collected_by_username: 'medics', collected_at: Time.current, collected_at_facility_id: @facility.id, collected_at_facility_name: @facility.name, bill_number: investigation.try(:[], 'bill_number'))
                next
              end

              if @investigation.state != 'payment_taken'
                @investigation.payment_taken
              end # Change State to PaymentDone

              queue = Investigation::Queue.find_by(id: @investigation.queue_id.to_s)
              queue.update(payment_taken: true) if queue.present?

              @appointment = Appointment.find_by(id: @investigation.appointment_id)
              CaseSheet::CreateInvestigationDetailService.call(@appointment, @investigation, @facility.id, @investigation.advised_by.to_s)
            end

          else
            updated_investigation_order = []
          end

          updated_investigation_order
        end

        def update_procedure_status(_appointment_id, placed_procedure_order)
          updated_procedure_order = if placed_procedure_order.present?

                                      placed_procedure_order.each do |procedure|
                                        current_procedure = @procedure_params.find { |h| h['id'] == procedure['id'] }

                                        current_procedure_status = current_procedure['status']

                                        procedure['status'] = current_procedure_status if current_procedure.present?
                                      end
                                    else
                                      []
                                    end

          updated_procedure_order
        end

        def update_medicine_status(_appointment_id, placed_medicine_order)
          updated_medicine_order = if placed_medicine_order.present?
                                     placed_medicine_order.each do |medicine|
                                       current_medicine = @medicine_params.find { |h| h['id'] == medicine['id'] }

                                       if current_medicine.present?
                                         current_medicine_status = current_medicine['status']
                                         medicine['status'] = current_medicine_status
                                       end
                                     end
                                   else
                                     []
                                   end

          updated_medicine_order
        end

        def create_data_request
          organisation_id = @organisation&.id
          facility_id = @facility&.id
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @original_params.permit!.to_hash

          if @order_data.present?
            order_data_hash = @order_data.try(:data) || {}
          else
            order_data_hash = {}
          end

          ApiIntegration::DataRequests::CreateService.call(data_hash, url, 'received', organisation_id, facility_id, order_data_hash)
        rescue StandardError
        end

        def create_data_response
          organisation_id = @organisation&.id
          facility_id = @facility&.id
          url = "#{params[:controller]}/#{params[:action]}"
          data_hash = @message
          if @order_data.present?
            order_data_hash = @order_data.try(:data) || {}
          else
            order_data_hash = {}
          end
          ApiIntegration::DataResponses::CreateService.call(data_hash, url, 'sent', organisation_id, facility_id, order_data_hash)
        rescue StandardError
        end
      end
    end
  end
end
