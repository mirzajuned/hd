module IpdCasesheetsHelper
  def user_level_surgical_notes(procedurenotes)
    user_level = procedurenotes.present? ? procedurenotes.select { |note| note.level == "user" } : []
  end

  def facility_level_surgical_notes(procedurenotes)
    facility_level = procedurenotes.present? ? procedurenotes.select { |note| note.level == "facility" } : []
  end

  def organisation_level_surgical_notes(procedurenotes)
    organisation_level = procedurenotes.present? ? procedurenotes.select { |note| note.level == "organisation" } : []
  end
end
