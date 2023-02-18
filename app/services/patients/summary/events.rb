module Patients
  module Summary
    module Events
      OPD_APPOINTMENT = { event: "OPD_APPOINTMENT", name: "OPD APPOINTMENT", id: 5110001 }
      OPD_RECORD = { event: "OPD_RECORD", name: "OPD RECORD", id: 5110002 }
      IPD_ADMISSION = { event: "IPD_ADMISSION", name: "IPD ADMISSION", id: 5110003 }
      IPD_OT = { event: "IPD_OT", name: "IPD OT", id: 5110004 }
      # IPD_DISCHARGE={event: "IPD_DISCHARGE", name: "PATIENT", id: 5110005}
      IPD_RECORD = { event: "IPD_RECORD", name: "IPD RECORD", id: 5110005 }
      # ADMISSION_NOTE={event: "ADMISSION_NOTE", name: "ADMISSION NOTE", id: 5110006}
      # OPERATIVE_NOTE={event: "OPERATIVE_NOTE", name: "OPERATIVE NOTE", id: 5110007}
      # DISCHARGE_NOTE={event: "DISCHARGE_NOTE", name: "DISCHARGE NOTE", id: 5110008}
      # WARD_NOTE={event: "WARD_NOTE", name: "WARD NOTE", id: 5110009}
      UPLOAD = { event: "UPLOAD", name: "UPLOAD", id: 5110006 }
      IPD_INVOICE = { event: "IPD_INVOICE", name: "IPD BILL", id: 5110007 }
      OPD_INVOICE = { event: "OPD_INVOICE", name: "OPD BILL", id: 5110008 }
      OPD_ADVANCE = { event: "OPD_ADVANCE", name: "OPD ADVANCE", id: 5110018 }
      IPD_ADVANCE = { event: "IPD_ADVANCE", name: "IPD ADVANCE", id: 5110019 }
      INSURANCE_INVOICE = { event: "INSURANCE_INVOICE", name: "INSURANCE INVOICE", id: 5110009 }
      CERTIFICATE = { event: "CERTIFICATE", name: "CERTIFICATE", id: 5110010 }
      PATIENT_REFERENCE = { event: "PATIENT_REFERENCE", name: "PATIENT REFERENCE", id: 5110011 }
      COUNSELLOR_RECORD = { event: "COUNSELLOR_RECORD", name: "COUNSELLOR RECORD", id: 5110012 }
      COUNSELLING_RECORD = { event: "COUNSELLING_RECORD", name: "COUNSELLING RECORD", id: 6110012 }
      NURSING_RECORD = { event: "NURSING_RECORD", name: "NURSING RECORD", id: 5110013 }
      OPTICAL_INVOICE = { event: "OPTICAL_INVOICE", name: "OPTICAL BILL", id: 5110014 }
      OPTICAL_ADVANCE = { event: "OPTICAL_ADVANCE", name: "OPTICAL BILL", id: 5110020 }
      PHARMACY_INVOICE = { event: "PHARMACY_INVOICE", name: "PHARMACY BILL", id: 5110015 }
      PHARMACY_ADVANCE = { event: "PHARMACY_ADVANCE", name: "PHARMACY BILL", id: 5110021 }
      OPTICAL_RETURN = { event: "OPTICAL_RETURN", name: "OPTICAL RETURN", id: 5110016 }
      PHARMACY_RETURN = { event: "PHARMACY_RETURN", name: "PHARMACY RETURN", id: 5110017 }
    end
  end
end
