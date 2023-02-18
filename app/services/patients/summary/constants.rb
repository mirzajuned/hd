module Patients
  module Summary
    class Constants
      include CommonConstant
      include OpdAppointment
      include Orthopedics
      include Ophthalmology
      include AssetUpload
    end
  end
end
## DELETE BELOW LINES WHEN THIS IS DONE.
# PS_OPD_LINKS_OPHTHALMOLOGY=[["edit_opd_records_ophthalmology_note_path", "E", "Edit OPD Summary", "fa fa-user" ], ["edit_opd_records_ophthalmology_note_path", "E", "Edit OPD Summary", "fa fa-user" ], ["edit_opd_records_ophthalmology_note_path", "E", "Edit OPD Summary", "fa fa-user" ], ["edit_opd_records_ophthalmology_note_path", "E", "Edit OPD Summary", "fa fa-user" ]]
