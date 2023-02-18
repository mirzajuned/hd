class OrganisationJobs::TpaContactsJob < ActiveJob::Base
  queue_as :urgent

  def perform(organisation_id)
    organisation = Organisation.find_by(id: organisation_id)

    contact_groups = [["Insurance", "insurance"], ["TPA", "tpa"]]
    contact_groups.each_with_index do |group|
      type = group[1]

      if type == "insurance"

        ins_contact_type = ContactGroup.find_by(name: 'Insurance', organisation_id: organisation.id)
        if ins_contact_type.present?
          ins_contact_type.update(is_deleted: false, contact_group_type: 'tpa')
          Contact.where(contact_group_id: ins_contact_type.id).update_all(contact_ype: 'tpa')
        else
          ins_contact_type = ContactGroup.create!(name: 'Insurance', is_deleted: false, contact_group_type: 'tpa', organisation_id: organisation.id)
        end

        contacts = get_insurance_contacts

        contacts.each_with_index do |contact|
          Contact.create(company_name: contact, display_name: contact, organisation_id: organisation.id, contact_group_id: ins_contact_type.id, is_deleted: false, provided_by: 'HG', contact_type: 'tpa')
        end

      elsif type == "tpa"

        tpa_contact_type = ContactGroup.find_by(name: 'TPA', organisation_id: organisation.id)
        if tpa_contact_type.present?
          tpa_contact_type.update(is_deleted: false, contact_group_type: 'tpa')
          Contact.where(contact_group_id: tpa_contact_type.id).update_all(contact_ype: 'tpa')
        else
          tpa_contact_type = ContactGroup.create!(name: 'TPA', is_deleted: false, contact_group_type: 'tpa', organisation_id: organisation.id)
        end

        contacts = get_tpa_contacts

        contacts.each_with_index do |contact|
          Contact.create(company_name: contact, display_name: contact, organisation_id: organisation.id, contact_group_id: tpa_contact_type.id, is_deleted: false, provided_by: 'HG', contact_type: 'tpa')
        end

      end
    end
  end

  private

  def get_insurance_contacts
    contacts = ["Aditya Birla Health Insurance Company Limited", "Apollo Munich Health Insurance Company Limited", "Bajaj Allianz General Insurance Company Limited", "Cholamandalam Ms General Insurance Company Limited", "Cigna TTK Health Insurance Co. Ltd", "Future Generali India Insurance Company Limited", "HDFC Ergo General Insurance Company Limited", "ICICI Lombard General Insurance Company Limited", "Iffco – Tokio General Insurance Co. Ltd.", "Max Bupa Health Insurance Company Limited", "Reliance General Insurance Company Limited", "Religare Health Insurance Company Limited", "Star Health And Allied Insurance Co. Ltd", "Universal Sompo General Insurance Company Limited"]
    return contacts
  end

  def get_tpa_contacts
    contacts = ["Alankit Healthcare TPA Limited", "Dedicated Healthcare Services TPA Private Limited", "E-Meditek TPA Services Limited", "Family Health Plan (TPA) Limited", "Genins India TPA Limited", "Good Health Plan TPA Limited", "Health India TPA Services Pvt Ltd", "Md India Healthcare Services (TPA) Private Limited", "Medi Assist India TPA Private Limited", "Medicare TPA Services India Private Limited", "Medsave Healthcare TPA Limited", "Paramount Healthcare Services TPA Private Limited", "SpurthiMeditech (TPA) Solutions Pvt Ltd", "United Healthcare Parekh TPA Private Limited", "Vidal Health TPA Private Limited", "Vipul Medcorp TPA Private Limited"]
    return contacts
  end
end
