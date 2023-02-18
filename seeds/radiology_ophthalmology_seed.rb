# bundle exec rake db:dump:radiology_ophthalmology_seed RAILS_ENV=development
RadiologyInvestigationData.where(specialty_id: 309988001).delete_all
RadiologyInvestigationData.create!(
  [

    { investigation_id: 120000001, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Chest', has_laterality: 'N', investigation_type: 'X-Ray', investigation_type_id: 363680008, options: [{ laterality: '410594000', loinc_code: '41811-1', is_custom: 'N', reference_loinc: '41811-1' }] },
    { investigation_id: 120000002, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Orbits', has_laterality: 'N', investigation_type: 'X-Ray', investigation_type_id: 363680008, options: [{ laterality: '410594000', loinc_code: '24854-2', is_custom: 'N', reference_loinc: '24854-2' }] },
    { investigation_id: 120000003, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Orbits FB', has_laterality: 'N', investigation_type: 'X-Ray', investigation_type_id: 363680008, options: [{ laterality: '410594000', loinc_code: '44208-7', is_custom: 'N', reference_loinc: '44208-7' }] },
    { investigation_id: 120000004, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Orbits Waters', has_laterality: 'N', investigation_type: 'X-Ray', investigation_type_id: 363680008, options: [{ laterality: '410594000', loinc_code: '37613-7', is_custom: 'N', reference_loinc: '37613-7' }] },
    { investigation_id: 120000005, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Skull & Orbits', has_laterality: 'N', investigation_type: 'X-Ray', investigation_type_id: 363680008, options: [{ laterality: '410594000', loinc_code: '43529-7', is_custom: 'N', reference_loinc: '43529-7' }] },
    { investigation_id: 120000006, specialty_id: 309988001, template_id: 244486005, investigation_name: '2-D ECHO', has_laterality: 'N', investigation_type: 'ECHO', investigation_type_id: 40701008, options: [{ laterality: '410594000', loinc_code: '34552-0', is_custom: 'N', reference_loinc: '34552-0' }] },
    { investigation_id: 120000007, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Brain', has_laterality: 'N', investigation_type: 'MRI', investigation_type_id: 113091000, options: [{ laterality: '410594000', loinc_code: '42392-1', is_custom: 'N', reference_loinc: '42392-1' }] },
    { investigation_id: 120000008, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Orbits', has_laterality: 'N', investigation_type: 'MRI', investigation_type_id: 113091000, options: [{ laterality: '410594000', loinc_code: '36777-1', is_custom: 'N', reference_loinc: '36777-1' }] },
    { investigation_id: 120000009, specialty_id: 309988001, template_id: 244486005, investigation_name: 'Orbits & Face', has_laterality: 'N', investigation_type: 'MRI', investigation_type_id: 113091000, options: [{ laterality: '410594000', loinc_code: '42303-8', is_custom: 'N', reference_loinc: '42303-8' }] },

  ]
)
