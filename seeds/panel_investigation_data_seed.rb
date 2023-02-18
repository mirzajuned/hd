# bundle exec rake db:dump:panel_investigation_data_seed RAILS_ENV=development

LaboratoryPanelInvestigationData.create!(
  [

    { srno: 4, investigation_id: 130000004, loinc_code: '787-2', investigation_name: 'Erythrocyte mean corpuscular volume [Entitic volume] by Automated count', short_name: 'Red blood cell count', loinc_class: '	HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "Male: 4.32-5.72 trillion cells/L*(4.32-5.72 million cells/mcL**)\nFemale: 3.90-5.03 trillion cells/L(3.90-5.03 million cells/mcL)" },

    { srno: 6, investigation_id: 130000006, loinc_code: '4544-3', investigation_name: 'Hematocrit [Volume Fraction] of Blood by Automated count', short_name: 'Hematocrit', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "Male: 38.8-50.0 percent\nFemale: 34.9-44.5 percent" },

    { srno: 7, investigation_id: 130000007, loinc_code: '6690-2', investigation_name: '	Leukocytes [#/​volume] in Blood by Automated count', short_name: 'White blood cell count', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "3.5-10.5 billion cells/L\n(3,500 to 10,500 cells/mcL)" },

    { srno: 8, investigation_id: 130000008, loinc_code: '777-3', investigation_name: 'Platelets [#/​volume] in Blood by Automated count', short_name: 'Platelet count', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "150-450 billion/L\n(150,000 to 450,000/mcL**)" },
    { srno: 9, investigation_id: 130000009, loinc_code: '11067-6', investigation_name: 'Bleeding Time', short_name: 'BT', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "2-5 minutes" },
    { srno: 10, investigation_id: 130000010, loinc_code: '81638-9', investigation_name: 'Clotting Time', short_name: 'CT', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "3-7 minutes" },
    { srno: 11, investigation_id: 130000011, loinc_code: '718-7', investigation_name: 'Heamoglobin%', short_name: 'CT', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "Males 13-18gm% Females 11-16gm%" },
    { srno: 39, investigation_id: 130000039, loinc_code: '57021-8', investigation_name: 'Hematocrit (PCV)', short_name: 'PCV', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "30 - 45%" },
    { srno: 40, investigation_id: 130000040, loinc_code: '26464-8', investigation_name: 'Leucocyte count (WBC)', short_name: 'WBC', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "4,000 - 11,000 cells/cu.mm." },
    { srno: 41, investigation_id: 130000041, loinc_code: '57021-8', investigation_name: 'Erythrocyte count (RBC)', short_name: 'RBC', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "3.5 - 5.5 million cells/cu.mm." },
    { srno: 42, investigation_id: 130000042, loinc_code: '26515-7', investigation_name: 'Platelet count', short_name: 'PC', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "1.5 - 4.0 Lakh cells/cu.mm." },
    { srno: 43, investigation_id: 130000043, loinc_code: '4537-7', investigation_name: 'ESR', short_name: 'ESR', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "1/2 Hour : 05 - 10 mm,  1 Hour 10 - 20 mm" },
    { srno: 44, investigation_id: 130000044, loinc_code: '4548-4', investigation_name: 'Glycocylated hemoglobin (HbA1C)', short_name: 'HbA1C', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "Non Diabetic : 4 - 6.5 %, Good control : 6.5 - 8.5%, Poor control : 8.5 - 10.5%" },
    { srno: 12, investigation_id: 130000012, loinc_code: '48159-8', investigation_name: 'HCV', short_name: 'HCV', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "NON REACTIVE" },
    { srno: 13, investigation_id: 130000013, loinc_code: '5195-3', investigation_name: 'Hbs Ag', short_name: 'Hbs Ab', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "NEGATIVE" },
    { srno: 14, investigation_id: 130000014, loinc_code: '69668-2', investigation_name: 'HIV ANTI BODY', short_name: 'HIV', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "NON REACTIVE" },
    { srno: 15, investigation_id: 130000015, loinc_code: '34532-2', investigation_name: 'BLOOD GROUP', short_name: 'BG', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "" },
    { srno: 16, investigation_id: 130000016, loinc_code: '34530-6', investigation_name: 'Rh Type', short_name: 'Rh Type', loinc_class: 'HEM/BC/Lab', test_type: 'BC/Lab', specialty_id: 309988001, normal_range: "" },
    { srno: 17, investigation_id: 130000017, loinc_code: '1558-6', investigation_name: 'Fasting Blood Sugar', short_name: 'Fasting Blood Sugar', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: "60-110 mg/dl" },
    { srno: 18, investigation_id: 1300000178, loinc_code: '74447-4', investigation_name: 'Corresponding  Urine Sugar', short_name: 'Urine Sugar', loinc_class: 'PANEL.CHEM', test_type: 'P', specialty_id: 261904005, normal_range: 'NIL' },
    { srno: 19, investigation_id: 130000018, loinc_code: '1504-0', short_name: 'PP Sugar', investigation_name: 'Post Prandial Blood Sugar', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Less Than 180 mg/dl' },
    { srno: 45, investigation_id: 130000045, loinc_code: '6299-2', short_name: 'BU', investigation_name: 'Blood Urea', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '20 - 45 mg/dl' },
    { srno: 46, investigation_id: 130000046, loinc_code: '2160-0', short_name: 'SC', investigation_name: 'Serum Creatine', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Male : 0.7 - 1.4 mg/dl,  Female : 0.6 - 1.2 mg/dl' },
    { srno: 20, investigation_id: 130000019, loinc_code: '2345-7', short_name: 'Random blood Sugar', investigation_name: 'Random blood Sugar', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '70-160 mg/dl' },

    { srno: 21, investigation_id: 130000020, loinc_code: '5778-6', short_name: 'Color', investigation_name: 'COLOR', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 22, investigation_id: 130000021, loinc_code: '###-1', short_name: 'REACTION', investigation_name: 'REACTION', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 23, investigation_id: 130000022, loinc_code: '53327-3', short_name: '	Bilirubin.total [Mass/​volume] in Urine by Automated test strip', investigation_name: 'ALBUMIN', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },
    { srno: 24, investigation_id: 130000023, loinc_code: '5792-7', short_name: 'Glucose [Mass/​volume] in Urine by Test strip', investigation_name: 'SUGAR', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 25, investigation_id: 130000024, loinc_code: '###-2', short_name: 'Pus cells', investigation_name: 'PUS CELLS', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 26, investigation_id: 130000025, loinc_code: '###-3', short_name: 'EPITHELIAL CELLS', investigation_name: 'EPITHELIAL CELLS', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 27, investigation_id: 130000026, loinc_code: '789-8', short_name: 'RBC', investigation_name: 'RBC', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 28, investigation_id: 130000027, loinc_code: '###-4', short_name: 'CAST', investigation_name: 'CAST', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 29, investigation_id: 130000028, loinc_code: '###-5', short_name: 'CRYSTALS', investigation_name: 'CRYSTALS', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 30, investigation_id: 130000029, loinc_code: '###-6', short_name: 'BACTERIA', investigation_name: 'BACTERIA', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 31, investigation_id: 130000030, loinc_code: '###-7', short_name: 'OTHERS', investigation_name: 'OTHERS', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '' },

    { srno: 32, investigation_id: 130000031, loinc_code: '2093-3', short_name: 'Cholesterol-Total(Serum,CHOD-POD)', investigation_name: 'Cholesterol-Total(Serum,CHOD-POD)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Desirable: < 200 Borderline High: 200-239 High: >= 240  Unit: mg/dL' },

    { srno: 33, investigation_id: 130000032, loinc_code: '2571-8', short_name: 'Triglycerides(Serum,GPO-POD)', investigation_name: 'Triglycerides(Serum,GPO-POD)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Normal: < 150 Borderline High: 150-199 High: 200-499 Very High: >= 500  Unit: mg/dL' },

    { srno: 34, investigation_id: 130000033, loinc_code: '2085-9', short_name: 'HDL Cholesterol(Serum,Direct Homogenous)', investigation_name: 'HDL Cholesterol(Serum,Direct Homogenous)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Major risk factor for heart disease: < 40 Negative risk factor for heart disease: >= 60  Unit: mg/dL' },

    { srno: 35, investigation_id: 130000034, loinc_code: '43396-1', short_name: 'Non HDL Cholesterol(Serum,Calculated)', investigation_name: 'Non HDL Cholesterol(Serum,Calculated)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Optimal: < 130 Desirable: 130-159 Borderline high: 159-189 High: 189-220 Very High: >= 220  Unit: mg/dL' },

    { srno: 36, investigation_id: 130000035, loinc_code: '18262-6', short_name: 'LDL Cholesterol(Serum,Calculated)', investigation_name: 'LDL Cholesterol (Serum,Calculated)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: 'Optimal: < 100 Near Optimal: 100-129 Borderline high: 130-159 High: 160-189 Very High: >= 190' },

    { srno: 37, investigation_id: 1300000336, loinc_code: '11054-4', short_name: 'LDL/HDL RATIO', investigation_name: 'LDL/HDL RATIO', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '2.5-3.5 ratio' },

    { srno: 38, investigation_id: 130000037, loinc_code: '9830-1', short_name: 'CHOL/HDL RATIO(Serum,Calculated)', investigation_name: 'CHOL/HDL RATIO(Serum,Calculated)', loinc_class: 'PANEL.CHEM', test_type: 'I', specialty_id: 261904005, normal_range: '3.5-5 ratio' },

    { srno: 47, investigation_id: 130000047, loinc_code: '18725-2', short_name: 'MB', investigation_name: 'MicroBiology', loinc_class: 'ATTACH.LAB', test_type: 'I', specialty_id: 261904005, normal_range: 'No Organism seen in both eyes.' }

  ]
)
