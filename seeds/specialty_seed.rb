# bundle exec rake db:dump:specialty_seed RAILS_ENV=development
Specialty.delete_all

Specialty.create!(
  [
    { id: '309988001', name: 'Ophthalmology', is_launched: true },
    { id: '309989009', name: 'Orthopedics', is_launched: true },
    { id: '394579002', name: 'Cardiology', is_launched: true },
    { id: '394537008', name: 'Pediatric', is_launched: true },
    { id: '394802001', name: 'General medicine', is_launched: true },
    { id: '394585009', name: 'Obstetrics and Gynecology', is_launched: true },
    { id: '394584008', name: 'Gastroenterology', is_launched: true },
    { id: '394582007', name: 'Dermatology', is_launched: true },
    { id: '394583002', name: 'Endocrinology', is_launched: true },
    { id: '394589003', name: 'Nephrology', is_launched: true },
    { id: '394591006', name: 'Neurology', is_launched: true },
    { id: '394810000', name: 'Rheumatology', is_launched: true },
    { id: '418112009', name: 'Pulmonary medicine', is_launched: true },
    { id: '465134681', name: 'Dental', is_launched: true }
  ]
)
