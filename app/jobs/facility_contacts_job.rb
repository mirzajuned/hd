class FacilityContactsJob < ActiveJob::Base
  queue_as :urgent

  def perform(*args)
    contact = Contact.find_by(id: args[0])
    if contact.present?
      facility_contacts = FacilityContact.where(contact_id: contact.id.to_s)
      facility_contacts_hash = facility_contacts.map { |facility_contact| facility_contact }

      facilities = Facility.where(organisation_id: contact.organisation_id.to_s)

      facilities.each do |facility|
        facility_contact_hash = facility_contacts_hash.find { |facility_contact| facility_contact[:facility_id].to_s == facility.id.to_s }
        if facility_contact_hash.present?
          facility_contact = FacilityContact.find_by(id: facility_contact_hash[:id].to_s)
        else
          facility_contact = FacilityContact.new
        end

        # Facility Contact Fields
        facility_contact[:display_name] = contact.display_name
        facility_contact[:salutation] = contact.salutation
        facility_contact[:first_name] = contact.first_name
        facility_contact[:middle_name] = contact.middle_name
        facility_contact[:last_name] = contact.last_name

        facility_contact[:company_name] = contact.company_name
        facility_contact[:abbreviation] = contact.abbreviation
        facility_contact[:designation] = contact.designation
        facility_contact[:department] = contact.department
        facility_contact[:website] = contact.website

        unless facility_contact_hash.present?
          facility_contact[:mobile_number] = contact.mobile_number
          facility_contact[:work_number] = contact.work_number
          facility_contact[:email] = contact.email

          facility_contact[:address_line_1] = contact.address_line_1
          facility_contact[:address_line_2] = contact.address_line_2
          facility_contact[:city] = contact.city
          facility_contact[:state] = contact.state
          facility_contact[:country] = contact.country
          facility_contact[:pincode] = contact.pincode
        end

        facility_contact[:for_invoice] = contact.for_invoice
        facility_contact[:for_expense] = contact.for_expense
        facility_contact[:is_deleted] = contact.is_deleted

        facility_contact[:contact_id] = contact.id.to_s
        facility_contact[:created_from] = "contact"

        facility_contact[:organisation_id] = facility.organisation_id.to_s
        facility_contact[:facility_id] = facility.id.to_s
        facility_contact[:contact_group_id] = contact.contact_group_id.to_s

        facility_contact.save!
      end
    end
  end
end
