module NavbarHelper
  def self.get_department_wise_data(department_id, current_facility)
    options = {}

    case department_id

    when '284748001'
      options["controller"] = "prescriptions"
      options["action"] =   "pharmacy_management"
      options["selected_url"] = "/inventory/stores/284748001"
      options["li_id"] = "pharmacy-management"
      options["link_id"] = "pharmacy_navigation"
      options["value"] = "PHARMACY DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = false
      options["push_state"] = ""

    when '50121007'
      options["controller"] = "prescriptions"
      options["action"] =   "optical_management"
      options["selected_url"] = "/inventory/stores/50121007"
      options["li_id"] = "optical-management"
      options["link_id"] = "optical_navigation"
      options["value"] = "OPTICAL DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = false
      options["push_state"] = ""

    when '309935007'
      options["controller"] = "investigation_management"
      options["action"] =   "index"
      options["selected_url"] = "/investigation_management/309935007"
      options["li_id"] = "ophthal-management"
      options["link_id"] = "ophthal_navigation"
      options["value"] = "OPHTHAL DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = true
      options["push_state"] = "ps"

    when '261904005'
      options["controller"] = "investigation_management"
      options["action"] =   "index"
      options["selected_url"] = "/investigation_management/261904005"
      options["li_id"] = "laboratory-management"
      options["link_id"] = "laboratory_navigation"
      options["value"] = "LAB DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = true
      options["push_state"] = "ps"

    when '309964003'
      options["controller"] = "investigation_management"
      options["action"] =   "index"
      options["selected_url"] = "/investigation_management/309964003"
      options["li_id"] = "radio-management"
      options["link_id"] = "radio_navigation"
      options["value"] = "RADIO DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = true
      options["push_state"] = "ps"

    when '224608005'
      options["controller"] = "dashboard"
      options["action"] =   "index"
      options["selected_url"] = "/dashboard"
      options["li_id"] = "admin-management"
      options["link_id"] = "admin_navigation"
      options["value"] = "ADMIN"
      options["fa_icon"] = "fa fa-user"
      options["remote"] = true
      options["push_state"] = "ps"

    when '450368792'
      options["controller"] = "tpa"
      options["action"] =   "insurance_management"
      options["selected_url"] = "/tpa/insurance_management"
      options["li_id"] = "tpa-management"
      options["link_id"] = "tpa_navigation"
      options["value"] = "TPA DEPT."
      options["fa_icon"] = "fa fa-building"
      options["remote"] = true
      options["push_state"] = "ps"

    when '225746001'
      options["controller"] = "inpatients"
      options["action"] =   "ward_management"
      options["selected_url"] = "/inpatients/ward_management"
      options["li_id"] = "ward-management"
      options["link_id"] = "ward_navigation"
      options["value"] = "WARD DEPT."
      options["fa_icon"] = "fa fa-bed"
      options["remote"] = true
      options["push_state"] = "ps"

    when '225728007'
      options["controller"] = ""
      options["action"] =   ""
      options["selected_url"] = ""
      options["li_id"] = "emergency-management"
      options["link_id"] = "emergency_navigation"
      options["value"] = "EMERGENCY DEPT."
      options["fa_icon"] = "fa fa-plus-square"
      options["remote"] = true
      options["push_state"] = "ps"

    when '485396012'
      options["controller"] = "outpatients"
      options["action"] =   "appointment_management"
      options["selected_url"] = "/outpatients/appointment_management"
      options["li_id"] = "appointment-management"
      options["link_id"] = "opd_navigation"
      options["value"] = "OPD"
      options["fa_icon"] = "fa fa-stethoscope"
      options["remote"] = true
      options["push_state"] = "ps"

    when '486546481'
      options["controller"] = "inpatients"
      options["action"] =   "admission_management"
      options["selected_url"] = "/inpatients/admission_management"
      options["li_id"] = "admission-management"
      options["link_id"] = "ipd_navigation"
      options["value"] = "IPD"
      options["fa_icon"] = "fa fa-ambulance"
      options["remote"] = true
      options["push_state"] = "ps"

    when '225738002'
      options["controller"] = "inpatients"
      options["action"] =   "ot_management"
      options["selected_url"] = "/inpatients/ot_management"
      options["li_id"] = "ot-management"
      options["link_id"] = "ot_navigation"
      options["value"] = "OT"
      options["fa_icon"] = "fa fa-heartbeat"
      options["remote"] = true
      options["push_state"] = "ps"

    when '116154003'
      options["controller"] = "patients"
      options["action"] =   "patient_management"
      options["selected_url"] = "/patients/patient_management"
      options["li_id"] = "patient-management"
      options["link_id"] = "patient_navigation"
      options["value"] = "PATIENT"
      options["fa_icon"] = "fa fa-user"
      options["remote"] = true
      options["push_state"] = "ps"
    end

    return options
  end
end
