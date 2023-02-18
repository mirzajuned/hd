class Inventory::Report::CollectionReportService
  class << self
    def call(total_list)
      @data_array = []
      calculate_data(total_list)

      @data_array
    end

    private

    def calculate_data(total_list)
      total_list.each_with_index do |list, index|
        sl_no = index + 1
        receipt_time = list.receipt_time&.strftime('%d/%m/%Y  %H:%M:%S')
        user_name = list.user_display_fields[:name]
        user_designation = list.user_display_fields[:designation]
        patient_id = list.patient_display_fields[:patient_id]
        patient = Patient.find_by(id: patient_id)
        patient_name = patient.fullname
        patient_age = patient.age
        patient_gender = patient.gender
        patient_identifier = patient.patient_identifier_id
        patient_mrn = patient.patient_mrn
        patient_mob = patient.mobilenumber
        address = "#{patient.address_1} " + patient.address_2.to_s
        patient_pincode = patient.pincode
        patient_state = patient.state
        patient_city = patient.city
        patient_district = patient.district
        patient_commune = patient.commune
        receipt_type = list.receipt_type
        receipt_no = list.receipt_display_fields[:receipt_no]
        mop = list.receipt_display_fields[:mode_of_payment]
        remark = list.receipt_display_fields[:comments]
        amount = list.receipt_display_fields[:receipt_amount] || 0
        bill_number = list.receipt_display_fields[:bill_no]
        @data_array << [
          sl_no, receipt_time, user_name, user_designation, patient_name, patient_age, patient_gender,
          patient_identifier, patient_mrn, patient_mob, address, patient_pincode, patient_state, patient_city,
          patient_district, patient_commune, receipt_type, receipt_no, mop, remark, amount, bill_number
        ]
      end
    end
  end
end
