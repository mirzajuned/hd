json.patient_id @patient_id
json.set! "patient_prescription" do
  json.array!(@prescriptions) do |prescription|
    user = User.find_by(id: prescription.doctor)
    facility = Facility.find_by(id: prescription.facility_id)
    @prescription_expiry_date = Date.current.yesterday
    @prescription_lowest_expiry_date = Date.current + 100.years

    json.prescription_id prescription.id
    json.doctor user.try(:fullname).to_s
    json.facility facility.try(:name).to_s
    json.prescription_date prescription.encounterdate.strftime("%d %b %Y %a")
    json.prescription_time prescription.encounterdate.strftime("%I:%M %p")

    json.set! "patient_prescription_details" do
      json.array!(prescription.medications) do |medication|
        # Calculate Prescription Expiry
        medication_duration_option = medication[:medicinedurationoption]
        if medication_duration_option == "M"
          medication_duration_option_full = "months"
        elsif medication_duration_option == "W"
          medication_duration_option_full = "weeks"
        elsif medication_duration_option == "D"
          medication_duration_option_full = "days"
        elsif medication_duration_option == "F"
          medication_duration_option_full = "Next Followup"
        end
        if medication_duration_option_full.present? && medication[:medicineduration].present?
          medication_duration_option_full = "months" if medication_duration_option_full == "Next Followup"

          prescription_expiry_date = Date.current + eval("#{medication[:medicineduration]}.#{medication_duration_option_full}")

          medication_duration_option_full = "Next Followup" if medication_duration_option_full == "Next Followup"
        else
          prescription_expiry_date = Date.current + 1.month
        end
        @prescription_expiry_date = prescription_expiry_date if prescription_expiry_date > @prescription_expiry_date
        @prescription_lowest_expiry_date = prescription_expiry_date if prescription_expiry_date < @prescription_lowest_expiry_date
        # Calculate Prescription Expiry Ends

        json.position medication[:position]
        json.medicinename medication[:medicinename]
        json.medicinequantity medication[:medicinequantity]
        json.medicinefrequency medication[:medicinefrequency]
        json.medicinetype medication[:medicinetype]
        json.full_medicinefrequency "#{medication[:medicinefrequency]} #{medication[:medicinetype]}".strip
        json.medicinedurationoption medication_duration_option
        json.medicineduration medication[:medicineduration]
        json.full_medicineduration "#{medication[:medicineduration]} #{medication_duration_option_full}".strip
        json.eyeside medication[:eyeside]
        json.medicineinstructions medication[:medicineinstructions]
        json.taper_id medication[:taper_id]

        unless medication[:taper_id] == "0" || medication[:taper_id] == nil || medication[:taper_id] == ""
          tapering_kit = TaperingKit.find_by(id: medication[:taper_id])

          if tapering_kit.present?
            json.set! "tapering_details" do
              json.array!(tapering_kit.try(:tapering_set)) do |tapering_set|
                json.id tapering_set[:id]
                json.number_of_days tapering_set[:number_of_days]
                json.start_date tapering_set[:start_date].strftime("%d %b %Y %a")
                json.end_date tapering_set[:end_date].strftime("%d %b %Y %a")
                json.start_time tapering_set[:start_time].strftime("%I:%M %p")
                json.end_time tapering_set[:end_time].strftime("%I:%M %p")
                json.frequency tapering_set[:frequency]

                # Calculate Lowest & Highest Based on Tapering
                if (tapering_set[:end_date] > @prescription_expiry_date) && (tapering_set[:end_date] > prescription_expiry_date)
                  @prescription_expiry_date = prescription_expiry_date = tapering_set[:end_date]
                end
                if (tapering_set[:end_date] < @prescription_lowest_expiry_date)
                  @prescription_lowest_expiry_date = tapering_set[:end_date]
                end
              end
            end
          end
        end

        prescription_expired = (true if (@prescription_expiry_date < Date.current)) || false

        json.prescription_expiry_date prescription_expiry_date.strftime("%d %b %Y %a")
        json.prescription_expired prescription_expired
      end
    end

    prescription_expired = (true if (@prescription_expiry_date < Date.current)) || false

    json.prescription_highest_expiry_date @prescription_expiry_date.strftime("%d %b %Y %a")
    json.prescription_lowest_expiry_date @prescription_lowest_expiry_date.strftime("%d %b %Y %a")
    json.prescription_expired prescription_expired
  end
end
