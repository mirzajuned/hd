# bundle exec rake db:dump:static_filter_seed RAILS_ENV=development

Reports::Filter.delete_all

# clinical/facility filters
Reports::Filter.create!(
  [
    { filter_name: 'age', filter_value_name: 'age', filter_type: 'range', category: 'clinical', value_type: 'integer', filter_group: 'clinical', type: 'opd' },
    { filter_name: 'gender', filter_value_name: 'gender_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'opd' },
    { filter_name: 'appointment type', filter_value_name: 'appointmenttype', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'opd' },
    { filter_name: 'sub appointment type', filter_value_name: 'appointment_type', filter_type: 'checkbox', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'opd' },
    { filter_name: 'bill type', filter_value_name: 'bill_type', filter_type: 'dropdown', category: 'financial', value_type: 'string', filter_group: 'financial' },
    { filter_name: 'department', filter_value_name: 'department_id', filter_type: 'dropdown', category: 'financial', value_type: 'string', filter_group: 'financial' },
    { filter_name: 'bill_status', filter_value_name: 'bill_status', filter_type: 'dropdown', category: 'financial', value_type: 'string', filter_group: 'financial', values_predefined: true },
    { filter_name: 'age', filter_value_name: 'age', filter_type: 'range', category: 'clinical', value_type: 'integer', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'gender', filter_value_name: 'gender_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'person_responsible', filter_value_name: 'person_responsible', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'event_category', filter_value_name: 'event_category', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'event_description', filter_value_name: 'event_description', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'sub_category', filter_value_name: 'sub_category', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'adverse_event' },
    { filter_name: 'conversion_status', filter_value_name: 'conversion_status', filter_type: 'dropdown', category: 'financial', value_type: 'string', filter_group: 'financial' },
    { filter_name: 'referral_type', filter_value_name: 'referral_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'referral' },
    { filter_name: 'referral_source', filter_value_name: 'referral_source', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'opd' },
    { filter_name: 'discount type', filter_value_name: 'discount_type', filter_type: 'dropdown', category: 'financial', value_type: 'string', filter_group: 'financial' }
  ]
)

Reports::Filter.create!(
  [
    { filter_name: 'age', filter_value_name: 'age', filter_type: 'range', category: 'clinical', value_type: 'integer', filter_group: 'clinical', type: 'ipd' },
    { filter_name: 'gender', filter_value_name: 'gender_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'ipd' },
    { filter_name: 'Mode of Hospitalisation', filter_value_name: 'moh', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'ipd' },
    { filter_name: 'Current Status', filter_value_name: 'ipd_current_status', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'ipd' },
    { filter_name: 'Admission Type', filter_value_name: 'admission_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'ipd' },
    { filter_name: 'Sort By', filter_value_name: 'date_wise', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'ipd' }
  ])

Reports::Filter.create!(
  [
    { filter_name: 'age', filter_value_name: 'age', filter_type: 'range', category: 'clinical', value_type: 'integer', filter_group: 'clinical', type: 'procedure' },
    { filter_name: 'gender', filter_value_name: 'gender_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'procedure' },
    { filter_name: 'Procedure Status', filter_value_name: 'procedure_state', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'procedure' },
    { filter_name: 'Sort By', filter_value_name: 'procedure_date_wise', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'procedure' },
    { filter_name: 'Advised By', filter_value_name: 'advised_by', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'procedure' },
    { filter_name: 'Performed By', filter_value_name: 'performed_by', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'procedure' }
  ])


Reports::Filter.create!(
  [
    { filter_name: 'age', filter_value_name: 'age', filter_type: 'range', category: 'clinical', value_type: 'integer', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'gender', filter_value_name: 'gender_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Investigation Status', filter_value_name: 'investigation_state', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Sort By', filter_value_name: 'investigation_date_wise', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Advised By', filter_value_name: 'advised_by', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Performed By', filter_value_name: 'performed_by', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Investigation Type', filter_value_name: 'investigation_type', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' },
    { filter_name: 'Performed At', filter_value_name: 'performed_at', filter_type: 'dropdown', category: 'clinical', value_type: 'string', filter_group: 'clinical', type: 'investigation' }

  ]  
)

Reports::Filter.create!(
  [
    { filter_name: 'role', filter_value_name: 'role_id', filter_type: 'dropdown', category: 'outpatient', value_type: 'string', filter_group: 'outpatient', type: 'user_wise_tat' },
    { filter_name: 'role', filter_value_name: 'role_id', filter_type: 'dropdown', category: 'outpatient', value_type: 'string', filter_group: 'outpatient', type: 'role_wise_tat' }
  ]
)

Reports::Filter.create!(
  [
    { filter_name: 'role', filter_value_name: 'role_id', filter_type: 'dropdown', category: 'notification', value_type: 'string', filter_group: 'notification', type: 'organisation_notification' }
  ]
)

# Organisation.where(is_migrated: true).update_all(is_migrated: false)
# bundle exec rake clinical:all_dynamic_dropdown RAILS_ENV=development

# bundle exec rake financial:doctor_dropdown RAILS_ENV=development cicd1 cicd2 cicd3
# Organisation.update_all(is_migrated: false)
# bundle exec rake clinical:facility_dropdown RAILS_ENV=cicd1      cicd1 cicd2 cicd3
# Organisation.update_all(is_migrated: false)
# bundle exec rake report_filters:store_dropdown RAILS_ENV=cicd1   cicd1 cicd2 cicd3
