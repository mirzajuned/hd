module PatientHistoryHelper
  def patient_history(_opdrecord)
    @opdrecord.allergy_histories.count > 0 || @opdrecord.personal_history_records.count > 0 ||
      @opdrecord.chief_complaints.count > 0 || @opdrecord.speciality_history_records.count > 0 ||
      @opdrecord.checkuptype.present? || @opdrecord.checkuptypecomments.present? ||
      @opdrecord.chiefcomplaint_comments.present? || @opdrecord.opthal_history_comment.present? ||
      @opdrecord.history_comment.present? || @opdrecord.others_allergies.present? ||
      @opdrecord.other_history.medical_history.present? || @opdrecord.other_history.family_history.present? ||
      @opdrecord.other_history.specialstatus.present?
  end
end
