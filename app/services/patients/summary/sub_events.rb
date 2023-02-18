module Patients::Summary::SubEvents
  SCHEDULED = { sub_event: 'SCHEDULED', name: 'SCHEDULED', id: 6110001 }.freeze # Appointment,Admission,OT
  ARRIVED = { sub_event: 'ARRIVED', name: 'ARRIVED', id: 6110002 }.freeze # Appointment, Admission
  ENGAGED = { sub_event: 'ENGAGED', name: 'ENGAGED', id: 6110003 }.freeze # Appointment,OT
  COMPLETED = { sub_event: 'COMPLETED', name: 'COMPLETED', id: 6110004 }.freeze # Appointment,OT
  RESCHEDULED = { sub_event: 'RESCHEDULED', name: 'RESCHEDULED', id: 6110005 }.freeze # Appointment,OT
  CANCELLED = { sub_event: 'CANCELLED', name: 'CANCELLED', id: 6110006 }.freeze # Appointment, Admission, OT
  REFUNDED = { sub_event: 'REFUNDED', name: 'REFUNDED', id: 61100022 }.freeze # Appointment, Admission, OT
  EDITED = { sub_event: 'EDITED', name: 'EDITED', id: 6110007 }.freeze # Appointment
  WORKFLOW = { sub_event: 'WORKFLOW', name: 'WORKFLOW', id: 6110008 }.freeze # Appointment
  AWAY = { sub_event: 'AWAY', name: 'AWAY', id: 6110009 }.freeze # Appointment
  CREATED = { sub_event: 'CREATED', name: 'CREATED', id: 6110010 }.freeze # OPDRecord,IPDRecord,CounsellorRecord,NursingRecord
  UPDATED = { sub_event: 'UPDATED', name: 'UPDATED', id: 6110011 }.freeze # OPDRecord,IPDRecord,CounsellorRecord,NursingRecord
  PRINTED = { sub_event: 'PRINTED', name: 'PRINTED', id: 6110012 }.freeze # OPDRecord,IPDRecord,CounsellorRecord,NursingRecord
  DELETED = { sub_event: 'DELETED', name: 'DELETED', id: 6110013 }.freeze # OPDRecord,IPDRecord,CounsellorRecord,NursingRecord
  ADMITTED = { sub_event: 'ADMITTED', name: 'ADMITTED', id: 6110014 }.freeze # Admission
  DISCHARGED = { sub_event: 'DISCHARGED', name: 'DISCHARGED', id: 6110015 }.freeze # Admission
  LINKED = { sub_event: 'LINKED', name: 'LINKED', id: 6110016 }.freeze # Ot
  UNLINKED = { sub_event: 'UNLINKED', name: 'UNLINKED', id: 6110017 }.freeze # Ot
  ADDED = { sub_event: 'ADDED', name: 'ADDED', id: 6110018 }.freeze # Upload
  REFERRED = { sub_event: 'REFERRED', name: 'REFERRED', id: 6110019 }.freeze # Refer
  SIGNEDOFF = { sub_event: 'SIGNEDOFF', name: 'SIGNED-OFF', id: 6110020 }.freeze # Sign-off to block edit OPDRecord.
  UNDOSIGNEDOFF = { sub_event: 'UNDOSIGNEDOFF', name: 'UNDO SIGNED-OFF', id: 6110021 }.freeze # Undo Sign-off to block edit OPDRecord.
  CHECKOUT = { sub_event: 'CHECKOUT', name: 'CHECKOUT', id: 6110022 }.freeze # Appointment
end
