# bundle exec rake db:dump:sub_specialty_seed RAILS_ENV=development
SubSpecialty.delete_all

SubSpecialty.create!(
  [
    { id: '422234006', name: 'General Ophthalmology', specialty_id: '309988001', specialty_name: 'Ophthalmology', is_default: true },
    { id: '193570009', name: 'Cataract', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '28726007', name: 'Cornea', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '394611003', name: 'Orbit & Occuloplasty', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '5665001', name: 'Medical Retina', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '110700004', name: 'Vitreo Retina', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '22066006', name: 'Paediatric & Strabismus', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '23986001', name: 'Glaucoma', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '394591006', name: 'Neuro-ophthalmology', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '19906005', name: 'Ocular Oncology', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '373391005', name: 'Refractive Surgery', specialty_id: '309988001', specialty_name: 'Ophthalmology' },
    { id: '128473001', name: 'Uveitis', specialty_id: '309988001', specialty_name: 'Ophthalmology' },

    { id: '78001009', name: 'General Orthopedics', specialty_id: '309989009', specialty_name: 'Orthopedics', is_default: true },
    { id: '53120007', name: 'Hand and Upper Extremity', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '40983000', name: 'Shoulder and Elbow', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '442095009', name: 'Total Joint Reconstruction(Arthroplasty)', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '394537008', name: 'Pediatric Orthopedics', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '731298009', name: 'Foot and ankle surgery', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '429680000', name: 'Spine surgery', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '419321007', name: 'Musculoskeletal oncology', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '702923000', name: 'Surgical Sports Medicine', specialty_id: '309989009', specialty_name: 'Orthopedics' },
    { id: '394801008', name: 'Orthopedic Trauma', specialty_id: '309989009', specialty_name: 'Orthopedics' },

    { id: '408443003', name: 'General Medicine', specialty_id: '394802001', specialty_name: 'General medicine' },

    { id: '158979008', name: 'General Dental', specialty_id: '465134681', specialty_name: 'Dental' }
  ]
)
