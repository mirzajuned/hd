#  bundle exec rake db:dump:ophthalmology_investigation_data_seed RAILS_ENV=development

OphthalmologyInvestigationData.delete_all

@laterality = [{ side_name: 'Bilateral', side_id: '40638003' },
               { side_name: 'Right', side_id: '18944008' },
               { side_name: 'Left', side_id: '8966001' },]
@speciality_id = '309988001'
@speciality_name = 'Ophthalmology'

OphthalmologyInvestigationData.create!(
  [
    # Cornea
    { region: ['cornea'], investigation_name: "Topography", investigation_id: "252830007", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Orbscan", investigation_id: "252830007B", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Specular", investigation_id: "252829002", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "UBM", investigation_id: "418218003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Slit Lamp photography", investigation_id: "16306001", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Confocal microscopy", investigation_id: "418396003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Corneal scraping", investigation_id: "259222004", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Culture and sensitivity", investigation_id: "252390002", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Contact Lens Trial", investigation_id: "57368009", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea'], investigation_name: "Aberrometry", investigation_id: "415837002", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },

    # Retina
    { region: ['retina'], investigation_name: "Screening", investigation_id: "390735007", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina'], investigation_name: "FFA , FA", investigation_id: "252822006", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina'], investigation_name: "Fundus photo", investigation_id: "20067007", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina'], investigation_name: "ICG", investigation_id: "252823001", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina'], investigation_name: "OCT-Angio", investigation_id: "700070005", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },

    # glaucoma
    { region: ['glaucoma'], investigation_name: "Gonioscopy", investigation_id: "76949005", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['glaucoma'], investigation_name: "Perimetry", investigation_id: "103752008", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['glaucoma'], investigation_name: "OCT-DISC", investigation_id: "172426003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['glaucoma'], investigation_name: "FDT", investigation_id: "392017002", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['glaucoma'], investigation_name: "HRT", investigation_id: "391999003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['glaucoma'], investigation_name: "GDx", investigation_id: "392005004", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },

    # cataract
    { region: ['cataract'], investigation_name: "A-Scan", investigation_id: "113113000", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cataract'], investigation_name: "IOL Master", investigation_id: "113113000AA", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cataract'], investigation_name: "Syringing", investigation_id: "29513000", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cataract'], investigation_name: "Specular Microscope", investigation_id: "397556008", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cataract'], investigation_name: "Keratometry", investigation_id: "252828005", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },

    # squint
    { region: ['squint'], investigation_name: "VEP", investigation_id: "63107007", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['squint'], investigation_name: "Orthoptics", investigation_id: "310106004", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['squint'], investigation_name: "EMG", investigation_id: "42803009", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['squint'], investigation_name: "Hess test", investigation_id: "252878007", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },

    # multiple regions
    { region: ['cornea', 'cataract'], investigation_name: "Pentacam", investigation_id: "252830007A", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea', 'glaucoma'], investigation_name: "Pachymetry", investigation_id: "410456003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea', 'glaucoma', 'cataract'], investigation_name: "AS OCT", investigation_id: "416369006A", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea', 'retina', 'glaucoma', 'cataract', 'squint'], investigation_name: "Clinical Photography", investigation_id: "169283005", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea', 'retina', 'glaucoma', 'cataract', 'squint'], investigation_name: "CPCV", investigation_id: "169283005AA", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['cornea', 'retina', 'glaucoma', 'cataract', 'squint'], investigation_name: "LVA", investigation_id: "360285005", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina', 'cataract'], investigation_name: "USG B-Scan", investigation_id: "425816006", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina', 'glaucoma', 'cataract'], investigation_name: "OCT-MACULA", investigation_id: "416369006B", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name },
    { region: ['retina', 'squint'], investigation_name: "ERG", investigation_id: "277008003", has_laterality: true, laterality: @laterality, speciality_id: @speciality_id, speciality_name: @speciality_name }
  ]
)
