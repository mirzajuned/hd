class OutreachJobs::UpdateCamppatientsJob < ActiveJob::Base
  queue_as :urgent

  def perform(_id)
    camp = Camp.find_by(id: _id)
    patient = CampPatient.where(camp_username: camp.username)
    patient.update_all(camp_name: camp.camp_name)
  end
end
