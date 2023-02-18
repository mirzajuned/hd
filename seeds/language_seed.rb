# bundle exec rake db:dump:language_seed RAILS_ENV=development
Language.delete_all

Language.create!(
  [
    { _id: 'en_001', name: 'English', locale: 'English', lcid_code: 'en', lcid_string: 'en-in', country_ids: Country.all.pluck(:id) },
    { _id: 'hi_002', name: 'Hindi', locale: 'Hindi', lcid_code: 'hi', lcid_string: 'hi', country_ids: ['IN_108'] },
    { _id: 'as_003', name: 'Assamese', locale: 'Assamese', lcid_code: 'as', lcid_string: 'as', country_ids: ['IN_108'] },
    { _id: 'bn_004', name: 'Bengali', locale: 'Bengali - India', lcid_code: 'bn', lcid_string: 'bn', country_ids: ['IN_108'] },
    { _id: 'gu_005', name: 'Gujarati', locale: 'Gujarati', lcid_code: 'gu', lcid_string: 'gu', country_ids: ['IN_108'] },
    { _id: 'kn_006', name: 'Kannada', locale: 'Kannada', lcid_code: 'kn', lcid_string: 'kn', country_ids: ['IN_108'] },
    { _id: 'ks_007', name: 'Kashmiri', locale: 'Kashmiri', lcid_code: 'ks', lcid_string: 'ks', country_ids: ['IN_108'] },
    { _id: 'ml_008', name: 'Malayalam', locale: 'Malayalam', lcid_code: 'ml', lcid_string: 'ml', country_ids: ['IN_108'] },
    { _id: 'mr_009', name: 'Marathi', locale: 'Marathi', lcid_code: 'mr', lcid_string: 'mr', country_ids: ['IN_108'] },
    { _id: 'ne_010', name: 'Nepali', locale: 'Nepali', lcid_code: 'ne', lcid_string: 'ne', country_ids: ['IN_108'] },
    { _id: 'or_011', name: 'Oriya', locale: 'Oriya', lcid_code: 'or', lcid_string: 'or', country_ids: ['IN_108'] },
    { _id: 'pa_012', name: 'Punjabi', locale: 'Punjabi', lcid_code: 'pa', lcid_string: 'pa', country_ids: ['IN_108'] },
    { _id: 'sa_013', name: 'Sanskrit', locale: 'Sanskrit', lcid_code: 'sa', lcid_string: 'sa', country_ids: ['IN_108'] },
    { _id: 'sd_014', name: 'Sindhi', locale: 'Sindhi', lcid_code: 'sd', lcid_string: 'sd', country_ids: ['IN_108'] },
    { _id: 'ta_015', name: 'Tamil', locale: 'Tamil', lcid_code: 'ta', lcid_string: 'ta', country_ids: ['IN_108'] },
    { _id: 'te_016', name: 'Telugu', locale: 'Telugu', lcid_code: 'te', lcid_string: 'te', country_ids: ['IN_108'] },
    { _id: 'ur_017', name: 'Urdu', locale: 'Urdu', lcid_code: 'ur', lcid_string: 'ur', country_ids: ['IN_108'] },
    { _id: 'ar_018', name: 'Arabic', locale: 'Arabic', lcid_code: 'ar', lcid_string: 'ar', country_ids: [] },
    { _id: 'pt_019', name: 'Portuguese', locale: 'Portuguese', lcid_code: 'pt', lcid_string: 'pt', country_ids: [] },
    { _id: 'es_020', name: 'Spanish', locale: 'Spanish', lcid_code: 'es', lcid_string: 'es', country_ids: [] },
    { _id: 'mg_021', name: 'Malagasy', locale: 'Malagasy', lcid_code: 'mg', lcid_string: 'mg', country_ids: [] },
    { _id: 'rw_022', name: 'Kinyarwanda', locale: 'Rwanda', lcid_code: 'rw', lcid_string: 'rw', country_ids: [] },
    { _id: 'sw_023', name: 'Swahili', locale: 'Swahili', lcid_code: 'sw', lcid_string: 'sw', country_ids: ['KE_121', 'TZ_227'] },
    { _id: 'fr_024', name: 'French', locale: 'French', lcid_code: 'fr', lcid_string: 'fr', country_ids: ['MU_148'] },
    { _id: 'vi_025', name: 'Vietnamese', locale: 'Vietnamese', lcid_code: 'vi', lcid_string: 'vi', country_ids: ['VN_254', 'KH_039'] },
    { _id: 'kh_026', name: 'Khmer', locale: 'Khmer', lcid_code: 'kh', lcid_string: 'kh', country_ids: ['KH_039'] },
    { _id: 'ch_027', name: 'Chinese', locale: 'Chinese', lcid_code: 'ch', lcid_string: 'ch', country_ids: ['KH_039'] }
  ]
)
