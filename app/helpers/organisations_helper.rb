module OrganisationsHelper
  def link_to_add_facility(partial, f, association, link_id, link_name)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(partial, f: builder, idn: id.to_s)
    end
    link_to(link_name, '#', id: link_id + f.index.to_s, class: 'add_facilites btn btn-sm btn-primary btn-square', modal: true, data: { id: id, fields: fields.gsub("\n", '') })
  end

  def link_to_add_user(partial, f, association, link_id, link_name)
    new_object = User.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(partial, f: builder, idn: id.to_s)
    end
    link_to(link_name, '#', id: link_id + f.index.to_s, class: 'btn btn-sm btn-primary btn-square', modal: true, data: { id: id, fields: fields.gsub("\n", '') })
  end

  def add_sub_form(partial, f, association)
    new_object = f.object.send(association).klass.new
    id = new_object.object_id
    fields = f.fields_for(association, new_object, child_index: id) do |builder|
      render(partial, f: builder, idn: id.to_s)
    end
    fields
  end

  # def organisation_sub_appointments
  #   sub_appointment = OrganisationAppointmentCategoryType.where(organisation_id: current_user.try(:organisation_id), is_active: true)

  #   return sub_appointment
  # end
end
