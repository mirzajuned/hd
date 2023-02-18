module AdmissionsHelper
  def self.admission_type_label(admission)
    admission_type_label = if admission.admission_type == 'same_day'
                             'label label-pink'
                           elsif admission.admission_type == 'emergency'
                             'label label-danger'
                           elsif admission.admission_type == 'planned'
                             'label label-orange'
                           end
    admission_type_label
  end

  def self.update_milestone(admission, label, position, user_id, ot_id = nil)
    milestone = admission.admission_milestones.new(label: label, position: position, user_id: user_id, ot_id: ot_id)
    milestone.save

    AdmissionListView.find_by(admission_id: admission.id)
                     .update(admission_milestones: admission.admission_milestones)
    OtListView.where(admission_id: admission.id)
              .each { |olv| olv.update(admission_milestones: admission.admission_milestones) }
  end
end
