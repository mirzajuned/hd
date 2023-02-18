module Mis::ClinicalReportsHelper
  def self.appointment_type_in_html(frequency)
    t_header = ''
    t_data = ''
    frequency.each do |key, val|
      t_header += "<th>#{key.to_s.titleize}</th>"
      t_data += "<td>#{val}</td>"
    end

    table = "<table class='table table-bordered'>
        <tr>
          #{t_header}
         </tr>
          <tr style='text-align: left;'>
          #{t_data}
          </tr>
        </table>"
  end

  def self.prepare_mis_job(appointment_id)
    object_config = {}
    object_config["class_name"] = "mis_appointments"
    object_config["method_name"] = "upsert"
    mandatory = {}
    appointment_id = AppointmentListView.find_by(appointment_id: appointment_id).try(:id)
    mandatory["appointment_id"] = appointment_id.to_s
    ProcessInBackgroundJob.set(queue: :urgent, wait_until: 0).perform_later(object_config, mandatory, {}, {})
  end
end
