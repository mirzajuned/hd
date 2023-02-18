class PatientGcmJob < ActiveJob::Base
  queue_as :delayed
  def perform(*args)
    patient = Patient.find_by(id: args[0])
    entity = args[1].nil? ? "" : args[1]
    action = args[2].nil? ? "" : args[2]
    organisation_id = args[3].nil? ? "" : args[3]
    options_params = define_patient_params({ :patient => patient, :entity => entity, :action => action })
    GoogleCloudMessaging.send_message(options_params, organisation_id)
  end

  private

  def define_patient_params(params = {})
    patient_params = {}
    patient_params[:entity] = params[:entity]
    patient_params[:action] = params[:action]
    patient_params[:patient_id] = params[:patient].id.to_s
    patient_params[:fullname] = params[:patient].fullname
    patient_params[:age] = params[:patient].age
    patient_params[:gender] = params[:patient].gender
    patient_params[:mobilenumber] = params[:patient].mobilenumber
    patient_params[:secondarymobilenumber] = params[:patient].secondarymobilenumber
    patient_params[:blood_group] = params[:patient].blood_group
    ### ADD MORE IF NECESSARY
    return patient_params
  end
end
