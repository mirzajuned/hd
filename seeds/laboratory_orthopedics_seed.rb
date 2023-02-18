# bundle exec rake db:dump:laboratory_orthopedics_seed RAILS_ENV=development
LaboratoryInvestigationData.where(specialty_id: 309989009).delete_all
LaboratoryInvestigationData.create!(
  [
    { srno: 1, investigation_id: 110000001, loinc_code: '17861-6', investigation_name: 'S. Calcium', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 2, investigation_id: 110000002, loinc_code: '2777-1', investigation_name: 'S. Phosphates', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 3, investigation_id: 110000003, loinc_code: '6768-6', investigation_name: 'Alk. Phosphatase', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 4, investigation_id: 110000004, loinc_code: '1989-3', investigation_name: '25(OH)D3 ', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 5, investigation_id: 110000005, loinc_code: '2731-8', investigation_name: 'S. Parathyrin (PTH)', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 6, investigation_id: 110000006, loinc_code: '2132-9', investigation_name: 'Vit B12', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 7, investigation_id: 110000007, loinc_code: '3084-1', investigation_name: 'S. Uric acid', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 8, investigation_id: 110000008, loinc_code: '718-7', investigation_name: 'Hgb', loinc_class: 'HEM/BC', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 9, investigation_id: 110000009, loinc_code: '58410-2', investigation_name: 'CBC', loinc_class: 'PANEL.HEM/BC', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 10, investigation_id: 110000053, loinc_code: '882-1', investigation_name: 'Blood Grouping', loinc_class: 'BLDBK', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 11, investigation_id: 110000054, loinc_code: '1250-0', investigation_name: 'Blood group cross matching', loinc_class: 'BLDBK', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 12, investigation_id: 110000010, loinc_code: '30341-2', investigation_name: 'ESR', loinc_class: 'HEM/BC', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 13, investigation_id: 110000011, loinc_code: '1988-5', investigation_name: 'CRP', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 14, investigation_id: 110000012, loinc_code: '74447-4', investigation_name: 'Urine Sugar', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 15, investigation_id: 110000040, loinc_code: '2339-0', investigation_name: 'RBS', loinc_class: 'CHEM', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 16, investigation_id: 110000041, loinc_code: '1558-6', investigation_name: 'Fasting Sugar', loinc_class: 'CHAL', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 17, investigation_id: 110000042, loinc_code: '1504-0', investigation_name: 'PP Sugar', loinc_class: 'CHAL', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 18, investigation_id: 110000013, loinc_code: '4548-4', investigation_name: 'Hgb A1c', loinc_class: 'HEM/BC', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    # Added Jan
    { srno: 19, investigation_id: 110000014, loinc_code: '24325-3', investigation_name: 'LFT', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },

    { srno: 20, investigation_id: 110000055, loinc_code: '1238-1', investigation_name: 'SGOT', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 21, investigation_id: 110000056, loinc_code: '1238-2', investigation_name: 'SGPT', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 22, investigation_id: 110000057, loinc_code: '1238-3', investigation_name: 'Bilirubin', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 23, investigation_id: 110000058, loinc_code: '1238-4', investigation_name: 'S. Proteins', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },

    { srno: 24, investigation_id: 110000015, loinc_code: '24362-6', investigation_name: 'RFT', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },

    { srno: 25, investigation_id: 110000059, loinc_code: '1238-5', investigation_name: 'S. Creat', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 26, investigation_id: 110000060, loinc_code: '1238-6', investigation_name: 'BUN', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },

    { srno: 27, investigation_id: 110000016, loinc_code: '55231-5', investigation_name: 'Electrolytes', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },

    { srno: 28, investigation_id: 110000061, loinc_code: '1238-7', investigation_name: 'S. Na', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 29, investigation_id: 110000062, loinc_code: '1238-8', investigation_name: 'S. K', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 30, investigation_id: 110000063, loinc_code: '1238-9', investigation_name: 'S. Cl', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    # End Line
    { srno: 31, investigation_id: 110000017, loinc_code: '48345-3', investigation_name: 'HIV', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 32, investigation_id: 110000018, loinc_code: '5196-1', investigation_name: 'HBS Ag', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 33, investigation_id: 110000019, loinc_code: '5198-7', investigation_name: 'HCV Ab', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 34, investigation_id: 110000043, loinc_code: '5291-0', investigation_name: 'VDRL', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 35, investigation_id: 110000044, loinc_code: '24314-7', investigation_name: 'TORCH', loinc_class: 'MICRO', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 36, investigation_id: 110000045, loinc_code: '9422-7', investigation_name: 'HSV-IgG', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 37, investigation_id: 110000046, loinc_code: '8040-8', investigation_name: 'Toxo-IgM', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 38, investigation_id: 110000047, loinc_code: '8039-0  ', investigation_name: 'Toxo-IgG', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 39, investigation_id: 110000048, loinc_code: '8015-0', investigation_name: 'Rubella-IgM', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 40, investigation_id: 110000049, loinc_code: '8014-3', investigation_name: 'Rubella-IgG', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 41, investigation_id: 110000050, loinc_code: '7853-5', investigation_name: 'CMV-IgM', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 42, investigation_id: 110000051, loinc_code: '7852-7', investigation_name: 'CMV-IgG', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 43, investigation_id: 110000052, loinc_code: '16944-1', investigation_name: 'HSV-IgM', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 44, investigation_id: 110000020, loinc_code: '11572-5', investigation_name: 'RA Factor', loinc_class: 'SERO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 45, investigation_id: 110000021, loinc_code: '33935-8', investigation_name: 'Anti-cCP Ab', loinc_class: 'SERO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 46, investigation_id: 110000022, loinc_code: '8061-4', investigation_name: 'ANA', loinc_class: 'SERO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 47, investigation_id: 110000023, loinc_code: '5130-0', investigation_name: 'dsDNA Ab', loinc_class: 'SERO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 48, investigation_id: 110000024, loinc_code: '48073-1', investigation_name: 'Thyroid Profile', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 49, investigation_id: 110000025, loinc_code: '53575-7', investigation_name: 'Lipid Profile', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 50, investigation_id: 110000026, loinc_code: '34528-0', investigation_name: 'Coagulation Profile', loinc_class: 'PANEL.COAG', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 51, investigation_id: 110000027, loinc_code: '50190-8', investigation_name: 'Iron Studies', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 52, investigation_id: 110000028, loinc_code: '24351-9', investigation_name: 'Electrophoresis', loinc_class: 'PANEL.CHEM', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 53, investigation_id: 110000029, loinc_code: '24357-6', investigation_name: 'Urine Analysis', loinc_class: 'PANEL.UA', test_type: 'P', panel_ids: [], specialty_id: 309989009 },
    { srno: 54, investigation_id: 110000030, loinc_code: '12235-8', investigation_name: 'Urine Microsocpy', loinc_class: 'UA', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 55, investigation_id: 110000031, loinc_code: '630-4', investigation_name: 'Bacteria Urine Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 56, investigation_id: 110000032, loinc_code: '600-7', investigation_name: 'Bacteria Blood Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 57, investigation_id: 110000033, loinc_code: '6462-6', investigation_name: 'Bacteria Wound Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 58, investigation_id: 110000034, loinc_code: '580-1', investigation_name: 'Fungus Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 59, investigation_id: 110000035, loinc_code: '543-9', investigation_name: 'Mycobacterium Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 60, investigation_id: 110000036, loinc_code: '635-3', investigation_name: 'Bacteria Anaerobe Culture', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 61, investigation_id: 110000037, loinc_code: '23658-8', investigation_name: 'Bacteria Antibiotic Susceptibility', loinc_class: 'ABXBACT', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 62, investigation_id: 110000038, loinc_code: '664-3', investigation_name: 'Gram Stn ', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 63, investigation_id: 110000039, loinc_code: '655-1', investigation_name: 'Acid fast Stn', loinc_class: 'MICRO', test_type: 'I', panel_ids: [], specialty_id: 309989009 },
    { srno: 64, investigation_id: 110000039, loinc_code: '18725-2', investigation_name: 'MicroBiology', loinc_class: 'ATTACH.LAB', test_type: 'P', panel_ids: [], specialty_id: 309989009 }
  ]
)
