module AnalyticsHelper
  def disease_histories_list
    names = [["Diabetes", "diabetes"], ["Hypertension", "hypertension"], ["Alcoholism", "alcoholism"],
             ["Smoking Tobacco", "smoking_tobacco"], ["Cardiac Disorder", "cardiac_disorder"],
             ["Steroid Intake", "steroid_intake"], ["Drug Abuse", "drug_abuse"], ["Hiv Aids", "hiv_aids"],
             ["Cancer Tumor", "cancer_tumor"], ["Tuberculosis", "tuberculosis"], ["Asthma", "asthma"],
             ["Cns Disorder Stroke", "cns_disorder_stroke"], ["Hypothyroidism", "hypothyroidism"],
             ["Hyperthyroidism", "hyperthyroidism"], ["Hepatitis Cirrhosis", "hepatitis_cirrhosis"],
             ["Renal Disorder", "renal_disorder"], ["Acidity", "acidity"], ["On insulin", "on_insulin"],
             ["On Aspirin Blood Thinners", "on_aspirin_blood_thinners"], ["Consanguinity", "consanguinity"],
             ["Thyroid Disorder", "thyroid_disorder"], ["Chewing Tobacco", "chewing_tobacco"],
             ["Rheumatoid Arthritis", "rheumatoid_arthritis"]]

    names = names.sort_by { |k| k[1] }
    return names
  end

  def eye_drop_allergy__historylist
    names = [["Tropicamide_P", "tropicamide_p"], ["Tropicamide", "tropicamide"], ["Timolol", "timolol"], ["Homide", "homide"],
             ["Latanoprost", "latanoprost"], ["Brimonidine", "brimonidine"], ["Travoprost", "travoprost"], ["Tobramycin", "tobramycin"],
             ["Moxifloxacin", "moxifloxacin"], ["Homatropine", "homatropine"], ["Pilocarpine", "pilocarpine"],
             ["Cyclopentolate", "cyclopentolate"], ["Atropine", "atropine"], ["Phenylephrine", "phenylephrine"], ["Tropicacyl", "tropicacyl"],
             ["Paracain", "paracain"], ["Ciplox", "ciplox"],
             ["Tropicamide P + Distilled Water","tropicamide_p_distilled_water" ], ["Tropicamide P + Lubrex","tropicamide_p_lubrex" ]]
    names = names.sort_by { |k| k[1] }
    return names
  end

  def get_commonly_used_diagnosis
    commonly_used_diagnosis = [["Eyelid disorders and inflammation", "Eyelid"], ["Lacrimal Gland Disorders", "Lacrimal Gland"], ["Disorders of orbit", "Orbit"], ["Conjunctival and Scleral Disorders", "Conjunctival / Scleral Disorders"], ["Corneal Disorders and Infection", "Cornea"], ["Uveal disorders", "Uvea"], ["Cataract", "Cataract"], ["Chorio-Retinal Disorders", "Retina"], ["Glaucoma", "Glaucoma"], ["Disorders of Optic Nerve", "Optic  Nerve"], ["Strabismus", "Squint"], ["Disorders of Refraction and accomodation", "Refraction"], ["Disorders of globe", "Disorders of globe"]]

    commonly_used_diagnosis = commonly_used_diagnosis.sort_by { |k| k[1] }
    return commonly_used_diagnosis
  end

  def get_ortho_icd_diagnoses
    ortho_icds = [['Knee', 'knee'], ['Shoulder', 'shoulder'], ['Spine', 'spine'], ['Hip', 'hip'], ['Foot Ankle', 'footankle'], ['Wrist Hand', 'wrist'], ['Elbow', 'elbow'], ['Systemic / General', 'systemic'], ['Cerebral Palsy', 'cp']]
    ortho_icds = ortho_icds.sort_by { |k| k[1] }

    return ortho_icds
  end

  def get_procedures_eye_region
    eye_regions = [['Plasty', 'plasty'], ['Squint', 'squint'], ['Cornea', 'cornea'], ['Retina', 'retina'], ['Glaucoma', 'glaucoma'], ['Cataract', 'cataract']]

    eye_regions = eye_regions.sort_by { |k| k[1] }
    return eye_regions
  end

  def get_chart_dataset_color
    chart_colors = ['#85C1E9', '#A3E4D7', '#A9DFBF', '#F9E79F', '#FAD7A0', '#F5CBA7', '#F6DDCC', '#ECF0F1', '#D7BDE2', '#D1F2EB', '#EAECEE', '#D5F5E3', '#90CAF9', '#fffac8', '#FFCDD2', '#C5CAE9', '#DCEDC8', '#FFECB3', '#E8DAEF', '#85C1E9', '#A3E4D7', '#A9DFBF', '#F9E79F', '#FAD7A0', '#F5CBA7', '#F6DDCC']

    return chart_colors
  end
end
