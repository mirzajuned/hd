module SystemicHistoryHelper
  def personal_histories_list
    [["Acidity", "acidity"],
     ["Alcoholism", "alcoholism"],
     ["Asthma", "asthma"],
     ["Cancer Tumor", "cancer_tumor"],
     ["Cardiac Disorder", "cardiac_disorder"],
     ["Cns Disorder Stroke", "cns_disorder_stroke"],
     ["Consanguinity", "consanguinity"],
     ["Diabetes", "diabetes"],
     ["Drug Abuse", "drug_abuse"],
     ["Hepatitis Cirrhosis", "hepatitis_cirrhosis"],
     ["Hiv Aids", "hiv_aids"],
     ["Hypertension", "hypertension"],
     ["Hyperthyroidism", "hyperthyroidism"],
     ["Hypothyroidism", "hypothyroidism"],
     ["On Aspirin Blood Thinners", "on_aspirin_blood_thinners"],
     ["On insulin", "on_insulin"],
     ["Renal Disorder", "renal_disorder"],
     ["Smoking Tobacco", "smoking_tobacco"],
     ["Steroid Intake", "steroid_intake"],
     ["Thyroid Disorder", "thyroid_disorder"],
     ["Tuberculosis", "tuberculosis"],
     ["Chewing Tobacco", "chewing_tobacco"],
     ["Rheumatoid Arthritis", "rheumatoid_arthritis"]]
  end

  def personal_history_names
    names = personal_histories_list.map { |history_list| history_list[1] }
    return names
  end

  def eye_drop_allergy_list
    [["Atropine", "atropine"],
     ["Brimonidine", "brimonidine"],
     ["Ciplox", "ciplox"],
     ["Cyclopentolate", "cyclopentolate"],
     ["Homatropine", "homatropine"],
     ["Homide", "homide"],
     ["Latanoprost", "latanoprost"],
     ["Moxifloxacin", "moxifloxacin"],
     ["Paracain", "paracain"],
     ["Phenylephrine", "phenylephrine"],
     ["Pilocarpine", "pilocarpine"],
     ["Timolol", "timolol"],
     ["Tobramycin", "tobramycin"],
     ["Travoprost", "travoprost"],
     ["Tropicacyl", "tropicacyl"],
     ["Tropicamide", "tropicamide"],
     ["Tropicamide_P", "tropicamide_p"],
     ["Tropicamide P + Distilled Water","tropicamide_p_distilled_water" ],
     ["Tropicamide P + Lubrex","tropicamide_p_lubrex" ]]
  end

  def eye_drop_allergy_names
    names = eye_drop_allergy_list.map { |allergy| allergy[1] }
    return names
  end
end
