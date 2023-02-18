# bundle exec rake db:dump:hg_seed_new RAILS_ENV=test

# 2 Organisation - One as Single Specialty and One as Multi Specialty
@organisations = Organisation.where(:id.in => ['58b6b43a6c55d3b8a5400a1e', '58b6b43f6c55d3b8a5400a1f'])

# 1 Workflow/India, Workflow/Vietnam | Non Workflow/India, Non Workflow/Vietnam
facility_ids = ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24',
                '58b6b4716c55d3b8a5400a25', '58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27',
                '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29']
@facilities = Facility.where(:id.in => facility_ids)
user_ids = ['58b6d1d55e751b4f33110aa3', '58b6d2545e751b4f33110aa4', '58b6d25a5e751b4f33110aa5', '58b6d2605e751b4f33110aa6',
            '58b6d26a5e751b4f33110aa7', '58b6d26f5e751b4f33110aa8', '58b6d2755e751b4f33110aa9', '58b6d27a5e751b4f33110aaa',
            '58b6d27e5e751b4f33110aab', '58b6d2845e751b4f33110aac', '58b6d2895e751b4f33110aad', '58b6d28f5e751b4f33110aae',
            '58b6d2955e751b4f33110aaf', '58b6d2995e751b4f33110ab0', '58b6d29e5e751b4f33110ab1', '58b7a8a3d58f42774c2274d2',
            '58b7a8a9d58f42774c2274d3', '58b7aa12d58f42774c2274da', '58b7aa12d58f42774c2274db', '591598faf9c44c04fbb92f62',
            '59159900f9c44c04fbb92f63', '590718c7476665a63dbdde40', '590718cc476665a63dbdde41', '5915987ff9c44c04fbb92f60',
            '59159886f9c44c04fbb92f61', '5b5ed12957554f5025beed74', '58b6d5b15e751b4f33110acc', '58b6d5b15e751b4f33110acd',
            '58b6d5b25e751b4f33110ace', '58b6d5b25e751b4f33110acf', '58b6d5b35e751b4f33110ad0', '58b6d5b35e751b4f33110ad1',
            '58b6d5b45e751b4f33110ad2', '58b6d5b45e751b4f33110ad3', '58b6d5b55e751b4f33110ad4', '58b6d5b55e751b4f33110ad5',
            '58b6d5b65e751b4f33110ad6', '58b7a8fbd58f42774c2274d6', '58b7a8fcd58f42774c2274d7', '58b7aa14d58f42774c2274de',
            '58b7aa15d58f42774c2274df', '5907197e476665a63dbdde42', '5907197e476665a63dbdde43', '59159935f9c44c04fbb92f64',
            '59159936f9c44c04fbb92f65', '58b6d7b25e751b4f33110ad7', '58b6d7b35e751b4f33110ad8', '58b6d7b35e751b4f33110ad9',
            '58b6d7b45e751b4f33110ada', '58b6d7b45e751b4f33110adb', '58b6d7b55e751b4f33110adc', '58b6d7b65e751b4f33110ade',
            '5da56e1e0d4c9c19cc6ec17d', '5dc16abe0d4c9ce78d996776', '5db16a060d4c9c9be179fde7', '5dc152650d4c9cdf401aaffd',
            '5dbab0cd0d4c9cc5dc0d9314', '5dc1604d0d4c9ce6c938be1a', '5dc170720d4c9ce78d9968c9', '5dc172ba0d4c9ce78d99697f',
            '5dc154670d4c9cdf401ab11a', '5dc1563e0d4c9cdf401ab29a', '5dc160fa0d4c9ce6c938bf3c', '5dc161850d4c9ce6c938bffc',
            '5def51540d4c9c13c76df2fe', '5def79940d4c9c16c74cc330', '5def90a90d4c9c186b126ad8', '5def92e90d4c9c186b126bff',
            '5f3bbbef0d4c9c2459bbac02']
@users = User.where(:id.in => user_ids)

# Delete_all before Re-Build
Inventory::Department.where(:facility_id.in => @facilities.pluck(:id)).delete_all
FacilitySetting.where(:facility_id.in => @facilities.pluck(:id)).delete_all
UserState.where(:facility_id.in => @facilities.pluck(:id)).delete_all
OrganisationsSetting.where(:organisation_id.in => @organisations.pluck(:id)).delete_all
UsersSetting.where(:organisation_id.in => @organisations.pluck(:id)).delete_all
OrganisationAppointmentType.where(:organisation_id.in => @organisations.pluck(:id)).delete_all
OrganisationAppointmentCategoryType.where(:organisation_id.in => @organisations.pluck(:id)).delete_all
AppointmentType.where(:organisation_id.in => @organisations.pluck(:id)).delete_all
@organisations.delete_all
@facilities.delete_all
@users.delete_all

# Create Organisations
organisation_options = {
  tagline: 'HealthCare for all', telephone: Faker::Number.number(10), fax: '(070) 412 3456', type: 'hospital', type_id: '22232009',
  address1: Faker::Address.street_name, address2: Faker::Address.street_address, city: 'Bengaluru', state: 'KARNATAKA',
  pincode: '560102', website: 'healthgraph.com', customised_letter_head: false, customised_footer: false, onboarding_completed: true,
  identifier_prefix: Faker::Name.name[0..2].upcase.to_s, logo: Faker::Company.logo, acceptancy_name: Faker::Name.name,
  acceptance_date: Date.current, query_contact: Faker::Number.number(10), paid_for_data: Faker::Boolean.boolean, pan_no: 'ABCDE1234F',
  st_no: '', footer_text: 'Thank You!', account_counter: Faker::Number.number(9), account_no: "HGT-ACC-#{Faker::Number.number(9)}",
  invoice_accessible: Faker::Boolean.boolean, invoice_access_code: '', account_expiry_date: Date.current + 100.years, currency_ids: ['INR001', 'VND001'], setup_type: 'single_user',
  referral_code: '218HGI3030', sms_contact_number: Faker::Number.number(10), country_id: 'IN_108',
  letter_head_customisations: { 'header_height' => '3', 'footer_height' => '0', 'left_margin' => '1', 'right_margin' => '1' }
}

@s_uniq_params = organisation_options.merge(id: '58b6b43a6c55d3b8a5400a1e', name: 'HG Single Specialty',
                                            email: 'single@healthgraph.in', specialty_ids: ['309988001'],
                                            integration_identifier: BSON::ObjectId.new, my_referral_code: 'HG_SINGLE')
@m_uniq_params = organisation_options.merge(id: '58b6b43f6c55d3b8a5400a1f', name: 'HG Multiple Specialty',
                                            email: 'multiple@healthgraph.in', specialty_ids: ['309988001', '309989009'],
                                            integration_identifier: BSON::ObjectId.new, my_referral_code: 'HG_MULTIPLE')

Organisation.new(@s_uniq_params).save!
Organisation.new(@m_uniq_params).save!

# Departments
@department_ids = ['485396012', '486546481', '225738002', '284748001', '50121007', '309935007', '261904005', '309964003',
                   '450368792', '225746001', '225728007', '224608005']

# Create Facility

# Workflow/India
# Workflow/Vietnam
# Non Workflow/India
# Non Workflow/Vietnam
# Single
facility_options = {
  address: Faker::Address.street_address, telephone: Faker::Number.number(10), fax: '(070) 412 3456', is_active: true, type_id: 257622000,
  show_finances: true, show_user_state: false, admission_schedule_list_length: 0, department_ids: @department_ids
}
@sw_i_uniq_params = facility_options.merge(id: '58b6b4626c55d3b8a5400a22', name: 'Workflow India', display_name: 'WF India',
                                           email: 'workflow@india.com', clinical_workflow: true, country_id: 'IN_108', abbreviation: 'WFIND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'INR001', currency_symbol: '₹',
                                           currency_ids: ['INR001'], time_zone: 'Asia/Kolkata', specialty_ids: ['309988001'],
                                           organisation_id: '58b6b43a6c55d3b8a5400a1e', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           state: 'KARNATAKA', city: 'Bengaluru', pincode: '560102')
@sw_v_uniq_params = facility_options.merge(id: '58b6b4686c55d3b8a5400a23', name: 'Workflow Vietnam', display_name: 'WF Vietnam',
                                           email: 'workflow@vietnam.com', clinical_workflow: true, country_id: 'VN_254', abbreviation: 'WFVND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'VND001', currency_symbol: '₫',
                                           currency_ids: ['VND001'], time_zone: 'Asia/Ho_Chi_Minh', specialty_ids: ['309988001'],
                                           organisation_id: '58b6b43a6c55d3b8a5400a1e', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           city: 'Thành phố Hà Nội', district: 'Quận Ba Đình', commune: 'Phường Phúc Xá')
@sn_i_uniq_params = facility_options.merge(id: '58b6b46c6c55d3b8a5400a24', name: 'Non Workflow India', display_name: 'NW India',
                                           email: 'nonworkflow@india.com', clinical_workflow: false, country_id: 'IN_108', abbreviation: 'NWIND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'INR001', currency_symbol: '₹',
                                           currency_ids: ['INR001'], time_zone: 'Asia/Kolkata', specialty_ids: ['309988001'],
                                           organisation_id: '58b6b43a6c55d3b8a5400a1e', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           state: 'KARNATAKA', city: 'Bengaluru', pincode: '560102')
@sn_v_uniq_params = facility_options.merge(id: '58b6b4716c55d3b8a5400a25', name: 'Non Workflow Vietnam', display_name: 'NW Vietnam',
                                           email: 'nonworkflow@vietnam.com', clinical_workflow: false, country_id: 'VN_254', abbreviation: 'NWVND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'VND001', currency_symbol: '₫',
                                           currency_ids: ['VND001'], time_zone: 'Asia/Ho_Chi_Minh', specialty_ids: ['309988001'],
                                           organisation_id: '58b6b43a6c55d3b8a5400a1e', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           city: 'Thành phố Hà Nội', district: 'Quận Ba Đình', commune: 'Phường Phúc Xá')
# Multipe
@mw_i_uniq_params = facility_options.merge(id: '58b6b4776c55d3b8a5400a26', name: 'Workflow India', display_name: 'MWF India',
                                           email: 'workflow@india.com', clinical_workflow: true, country_id: 'IN_108', abbreviation: 'WFIND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'INR001', currency_symbol: '₹',
                                           currency_ids: ['INR001'], time_zone: 'Asia/Kolkata', specialty_ids: ['309988001', '309989009'],
                                           organisation_id: '58b6b43f6c55d3b8a5400a1f', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           state: 'KARNATAKA', city: 'Bengaluru', pincode: '560102')
@mw_v_uniq_params = facility_options.merge(id: '58b6b47c6c55d3b8a5400a27', name: 'Workflow Vietnam', display_name: 'MWF Vietnam',
                                           email: 'workflow@vietnam.com', clinical_workflow: true, country_id: 'VN_254', abbreviation: 'WFVND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'VND001', currency_symbol: '₫',
                                           currency_ids: ['VND001'], time_zone: 'Asia/Ho_Chi_Minh', specialty_ids: ['309988001', '309989009'],
                                           organisation_id: '58b6b43f6c55d3b8a5400a1f', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           city: 'Thành phố Hà Nội', district: 'Quận Ba Đình', commune: 'Phường Phúc Xá')
@mn_i_uniq_params = facility_options.merge(id: '58b6b5366c55d3b8a5400a28', name: 'Non Workflow India', display_name: 'MNW India',
                                           email: 'nonworkflow@india.com', clinical_workflow: false, country_id: 'IN_108', abbreviation: 'NWIND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'INR001', currency_symbol: '₹',
                                           currency_ids: ['INR001'], time_zone: 'Asia/Kolkata', specialty_ids: ['309988001', '309989009'],
                                           organisation_id: '58b6b43f6c55d3b8a5400a1f', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           state: 'KARNATAKA', city: 'Bengaluru', pincode: '560102')
@mn_v_uniq_params = facility_options.merge(id: '58b6b53b6c55d3b8a5400a29', name: 'Non Workflow Vietnam', display_name: 'MNW Vietnam',
                                           email: 'nonworkflow@vietnam.com', clinical_workflow: false, country_id: 'VN_254', abbreviation: 'NWVND',
                                           integration_identifier: BSON::ObjectId.new, currency_id: 'VND001', currency_symbol: '₫',
                                           currency_ids: ['VND001'], time_zone: 'Asia/Ho_Chi_Minh', specialty_ids: ['309988001', '309989009'],
                                           organisation_id: '58b6b43f6c55d3b8a5400a1f', user_ids: [], invoice_compulsory: Faker::Boolean.boolean,
                                           city: 'Thành phố Hà Nội', district: 'Quận Ba Đình', commune: 'Phường Phúc Xá')

Facility.new(@sw_i_uniq_params).save!
Facility.new(@sw_v_uniq_params).save!
Facility.new(@sn_i_uniq_params).save!
Facility.new(@sn_v_uniq_params).save!
Facility.new(@mw_i_uniq_params).save!
Facility.new(@mw_v_uniq_params).save!
Facility.new(@mn_i_uniq_params).save!
Facility.new(@mn_v_uniq_params).save!

user_dob = Date.today - 25.years
# Single Hospital Users
User.create!(
  [
    # Admin
    { id: BSON::ObjectId('58b6d1d55e751b4f33110aa3'), salutation: 'Mrs', fullname: 'HOSPA ADMIN', designation: 'Admin',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@admin.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_admin',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [6868009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['224608005'] },
    # Owner
    { id: BSON::ObjectId('58b6d2545e751b4f33110aa4'), salutation: 'Mr', fullname: 'HOSPA OWNER', designation: 'Owner',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@owner.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_owner',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [160943002], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['224608005'] },
    # Doctor
    { id: BSON::ObjectId('58b6d25a5e751b4f33110aa5'), salutation: 'Dr', fullname: 'HOSPA DOC', designation: 'Doctor',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@doc.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_doc',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [158965000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    #Doctor Clinical Auditor
    { id: BSON::ObjectId('5f3bbbef0d4c9c2459bbac02'),salutation: 'Dr', fullname: 'hospa_doctorclinicalauditor', designation: 'doctorclinicalauditor',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@doctorclinicalauditor.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Ghaziabad',
      state: 'Uttar Pradesh', pincode: '201002', educational_qual: [''], work_exp: [''], username: 'hospa_doctorca',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23'],
      role_ids: [158966000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ["485396012", "486546481", "225738002"]},
    # Doctor Admin
    { id: BSON::ObjectId('58b6d2605e751b4f33110aa6'), salutation: 'Dr', fullname: 'HOSPA DOCADMIN', designation: 'Doctor Admin',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@docadmin.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_docadmin',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [158965000, 6868009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001', '224608005'] },
    # Doctor Owner
    { id: BSON::ObjectId('58b6d26a5e751b4f33110aa7'), salutation: 'Dr', fullname: 'HOSPA DOCOWNER', designation: 'Doctor Owner',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@docowner.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_docowner',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [158965000, 160943002], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001', '224608005'] },
    # Centre Head
    { id: BSON::ObjectId('5da56e1e0d4c9c19cc6ec17d'), salutation: 'Mr', fullname: 'center head', designation: 'center head',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'cneterhead@gmail.com', employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'centerhead',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22'],
      role_ids: [686800945], department_id: '224608005', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['224608005'] },
    { id: BSON::ObjectId('5dc16abe0d4c9ce78d996776'), salutation: 'Mr', fullname: 'HOSPA CNTHB', designation: 'Center head',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@cnthb.com', employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_cnthb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22'],
      role_ids: [686800945], department_id: '224608005', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['224608005'] },
    # Optometrist
    { id: BSON::ObjectId('58b6d26f5e751b4f33110aa8'), salutation: 'Mr', fullname: 'HOSPA OPTOA', designation: 'Optometrist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@optoa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_optoa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [28229004], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d2755e751b4f33110aa9'), salutation: 'Ms', fullname: 'HOSPA OPTOB', designation: 'Optometrist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@optob.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_optob',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [28229004], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # AR/NCT
    { id: BSON::ObjectId('5db16a060d4c9c9be179fde7'), salutation: 'Ms', fullname: 'ar_nct', designation: 'AR/NCT',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'ar_nct@gmail.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address:
      Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'ar_nct',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [28221005], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5dc152650d4c9cdf401aaffd'), salutation: 'Mr', fullname: 'HOSPA ARNCTB', designation: 'ar_nct',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@arnctb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address:
      Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_arctb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [28221005], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Cashier
    { id: BSON::ObjectId('5dbab0cd0d4c9cc5dc0d9314'), salutation: 'Mr', fullname: 'Cashier', designation: 'Cashier',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'cashier@gmail.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'cashier',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159562000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5dc1604d0d4c9ce6c938be1a'), salutation: 'Mr', fullname: 'HOSPA CASHB', designation: 'Cashier',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@cashb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_casb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159562000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Receptionist
    { id: BSON::ObjectId('58b6d27a5e751b4f33110aaa'), salutation: 'Mrs', fullname: 'HOSPA RECA', designation: 'Receptionist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@reca.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_reca',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159561009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d27e5e751b4f33110aab'), salutation: 'Ms', fullname: 'HOSPA RECB', designation: 'Receptionist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@recb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_recb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159561009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Floor Manager
    { id: BSON::ObjectId('5def51540d4c9c13c76df2fe'), salutation: 'Mr', fullname: 'HOSPA FMRGA', designation: 'floor manager',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@fmrga.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_fmrga',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [59561000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5def79940d4c9c16c74cc330'), salutation: 'Mr', fullname: 'HOSPA FMGRB', designation: 'floor manager',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@fmgrb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_fmgrb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b46c6c55d3b8a5400a24'],
      role_ids: [59561000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Counsellor
    { id: BSON::ObjectId('58b6d2845e751b4f33110aac'), salutation: 'Mr', fullname: 'HOSPA CONA', designation: 'Counsellor',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@cona.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_cona',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [499992366], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d2895e751b4f33110aad'), salutation: 'Mrs', fullname: 'HOSPA CONB', designation: 'Counsellor',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@conb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_conb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [499992366], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Pharmacist
    { id: BSON::ObjectId('58b6d28f5e751b4f33110aae'), salutation: 'Mr', fullname: 'HOSPA PHAA', designation: 'Pharmacist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@phaa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_phaa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/pharmacy_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [46255001], department_id: '284748001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['284748001'] },
    { id: BSON::ObjectId('58b6d2955e751b4f33110aaf'), salutation: 'Ms', fullname: 'HOSPA PHAB', designation: 'Pharmacist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@phab.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_phab',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/pharmacy_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [46255001], department_id: '284748001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['284748001'] },
    # Optician
    { id: BSON::ObjectId('58b6d2995e751b4f33110ab0'), salutation: 'Mr', fullname: 'HOSPA OPTA', designation: 'Optician',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@opta.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_opta',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/optical_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [387619007], department_id: '50121007', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['50121007'] },
    { id: BSON::ObjectId('58b6d29e5e751b4f33110ab1'), salutation: 'Ms', fullname: 'HOSPA OPTB', designation: 'Optician',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@optb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_optb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/optical_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [387619007], department_id: '50121007', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['50121007'] },
    # Nurse
    { id: BSON::ObjectId('58b7a8a3d58f42774c2274d2'), salutation: 'Mr', fullname: 'HOSPA NURA', designation: 'Nurse',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@nura.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_nura',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [106292003], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b7a8a9d58f42774c2274d3'), salutation: 'Ms', fullname: 'HOSPA NURB', designation: 'Nurse',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@nurb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_nurb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [106292003], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Fellow
    { id: BSON::ObjectId('58b7aa12d58f42774c2274da'), salutation: 'Mr', fullname: 'HOSPA FELA', designation: 'Fellow',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@fela.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_fela',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [405277009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b7aa12d58f42774c2274db'), salutation: 'Ms', fullname: 'HOSPA FELB', designation: 'Fellow',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@felb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_felb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [405277009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Lab Technician
    # Oph
    { id: BSON::ObjectId('591598faf9c44c04fbb92f62'), salutation: 'Mr', fullname: 'HOSPA OPHA', designation: 'Oph Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@opha.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_opha',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [2822900478], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309935007'] },
    { id: BSON::ObjectId('59159900f9c44c04fbb92f63'), salutation: 'Ms', fullname: 'HOSPA OPHB', designation: 'Oph Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@ophb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_ophb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [2822900478], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309935007'] },
    # Lab
    { id: BSON::ObjectId('590718c7476665a63dbdde40'), salutation: 'Mr', fullname: 'HOSPA LABA', designation: 'Lab Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@laba.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_laba',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159282002], department_id: '261904005', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['261904005'] },
    { id: BSON::ObjectId('590718cc476665a63dbdde41'), salutation: 'Ms', fullname: 'HOSPA LABB', designation: 'Lab Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@labb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_labb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [159282002], department_id: '261904005', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['261904005'] },
    # Rad
    { id: BSON::ObjectId('5915987ff9c44c04fbb92f60'), salutation: 'Mr', fullname: 'HOSPA RADA', designation: 'Rad Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@rada.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_rada',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [41904004], department_id: '309964003', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309964003'] },
    { id: BSON::ObjectId('59159886f9c44c04fbb92f61'), salutation: 'Ms', fullname: 'HOSPA RADB', designation: 'Rad Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@radb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_radb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [41904004], department_id: '309964003', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309964003'] },
    # TPA
    { id: BSON::ObjectId('5b5ed12957554f5025beed74'), salutation: 'Mr', fullname: 'HOSPA TPA', designation: 'TPA',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospa@tpa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospa_tpa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/tpa/insurance_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4626c55d3b8a5400a22', '58b6b4686c55d3b8a5400a23', '58b6b46c6c55d3b8a5400a24', '58b6b4716c55d3b8a5400a25'],
      role_ids: [573021946], department_id: '450368792', organisation_id: BSON::ObjectId('58b6b43a6c55d3b8a5400a1e'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['485396012', '486546481', '225738002', '225746001'] }
  ]
)

# Multiple Hospital Users
User.create!(
  [
    # Admin
    { id: BSON::ObjectId('58b6d5b15e751b4f33110acc'), salutation: 'Mrs', fullname: 'HOSPB ADMIN', designation: 'Admin',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@admin.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_admin',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [6868009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['224608005'] },
    # Owner
    { id: BSON::ObjectId('58b6d5b15e751b4f33110acd'), salutation: 'Mr', fullname: 'HOSPB OWNER', designation: 'Owner',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@owner.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_owner',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [160943002], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['224608005'] },
    # Doctor
    { id: BSON::ObjectId('58b6d5b25e751b4f33110ace'), salutation: 'Dr', fullname: 'HOSPB DOC', designation: 'Doctor',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@doc.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_doc',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [158965000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Doctor Admin
    { id: BSON::ObjectId('58b6d5b25e751b4f33110acf'), salutation: 'Dr', fullname: 'HOSPB DOCADMIN', designation: 'Doctor Admin',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@docadmin.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_docadmin',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [158965000, 6868009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001', '224608005'] },
    # Doctor Owner
    { id: BSON::ObjectId('58b6d5b35e751b4f33110ad0'), salutation: 'Dr', fullname: 'HOSPB DOCOWNER', designation: 'Doctor Owner',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@docowner.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_docowner',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [158965000, 160943002], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001', '224608005'] },
    # Centre Head
    { id: BSON::ObjectId('5dc170720d4c9ce78d9968c9'), salutation: 'Mr', fullname: 'HOSPB CNTHA', designation: 'center head',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@cntha.com', employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address:  Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_cntha',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26'],
      role_ids: [686800945], department_id: '224608005', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['224608005'] },
    { id: BSON::ObjectId('5dc172ba0d4c9ce78d99697f'), salutation: 'Mr', fullname: 'HOSPB CNTHB', designation: 'center head',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@cnthb.com', employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_cnthb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/dashboard', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26'],
      role_ids: [686800945], department_id: '224608005', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['224608005'] },
    # Optometrist
    { id: BSON::ObjectId('58b6d5b35e751b4f33110ad1'), salutation: 'Mr', fullname: 'HOSPB OPTOA', designation: 'Optometrist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@optoa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_optoa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [28229004], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d5b45e751b4f33110ad2'), salutation: 'Ms', fullname: 'HOSPB OPTOB', designation: 'Optometrist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@optob.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_optob',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [28229004], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # AR/NCT
    { id: BSON::ObjectId('5dc154670d4c9cdf401ab11a'), salutation: 'Mr', fullname: 'HOSPB ARNCTA', designation: 'ar_nct',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@arncta.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_arncta',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [28221005], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5dc1563e0d4c9cdf401ab29a'), salutation: 'Mr', fullname: 'HOSPB ARNCTB', designation: 'ar_nct',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@arnctb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_arnctb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [28221005], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Cashier
    { id: BSON::ObjectId('5dc160fa0d4c9ce6c938bf3c'), salutation: 'Mr', fullname: 'HOSPB CASA', designation: 'cashier',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospab@casa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_casa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159562000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5dc161850d4c9ce6c938bffc'), salutation: 'Mr', fullname: 'HOSPB CASB', designation: 'cashier',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@casb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_casb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159562000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Receptionist
    { id: BSON::ObjectId('58b6d5b45e751b4f33110ad3'), salutation: 'Mrs', fullname: 'HOSPB RECA', designation: 'Receptionist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@reca.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_reca',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159561009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d5b55e751b4f33110ad4'), salutation: 'Ms', fullname: 'HOSPB RECB', designation: 'Receptionist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@recb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_recb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159561009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Floor Manager
    { id: BSON::ObjectId('5def90a90d4c9c186b126ad8'), salutation: 'Ms', fullname: 'HOSPB FMRGA', designation: 'floor manager',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@fmrga.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_fmrga',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [59561000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5def92e90d4c9c186b126bff'), salutation: 'Ms', fullname: 'HOSPB FMGRB', designation: 'floor manager',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@fmgrb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_fmgrb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b5366c55d3b8a5400a28'],
      role_ids: [59561000], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Counsellor
    { id: BSON::ObjectId('58b6d5b55e751b4f33110ad5'), salutation: 'Mr', fullname: 'HOSPB CONA', designation: 'Counsellor',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@cona.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_cona',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [499992366], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('58b6d5b65e751b4f33110ad6'), salutation: 'Mrs', fullname: 'HOSPB CONB', designation: 'Counsellor',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@conb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_conb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [499992366], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Pharmacist
    { id: BSON::ObjectId('58b7a8fbd58f42774c2274d6'), salutation: 'Mr', fullname: 'HOSPB PHAA', designation: 'Pharmacist',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@phaa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_phaa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/pharmacy_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [46255001], department_id: '284748001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['284748001'] },
    { id: BSON::ObjectId('58b7a8fcd58f42774c2274d7'), salutation: 'Ms', fullname: 'HOSPB PHAB', designation: 'Pharmacist',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@phab.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_phab',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/pharmacy_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [46255001], department_id: '284748001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['284748001'] },
    # Optician
    { id: BSON::ObjectId('58b7aa14d58f42774c2274de'), salutation: 'Mr', fullname: 'HOSPB OPTA', designation: 'Optician',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@opta.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_opta',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/optical_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [387619007], department_id: '50121007', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['50121007'] },
    { id: BSON::ObjectId('58b7aa15d58f42774c2274df'), salutation: 'Ms', fullname: 'HOSPB OPTB', designation: 'Optician',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@optb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_optb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/prescriptions/optical_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [387619007], department_id: '50121007', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['50121007'] },
    # Nurse
    { id: BSON::ObjectId('5907197e476665a63dbdde42'), salutation: 'Mr', fullname: 'HOSPB NURA', designation: 'Nurse',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@nura.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_nura',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [106292003], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('5907197e476665a63dbdde43'), salutation: 'Ms', fullname: 'HOSPB NURB', designation: 'Nurse',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@nurb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_nurb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [106292003], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Fellow
    { id: BSON::ObjectId('59159935f9c44c04fbb92f64'), salutation: 'Mr', fullname: 'HOSPB FELA', designation: 'Fellow',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@fela.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_fela',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [405277009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    { id: BSON::ObjectId('59159936f9c44c04fbb92f65'), salutation: 'Ms', fullname: 'HOSPB FELB', designation: 'Fellow',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@felb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_felb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/outpatients/appointment_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [405277009], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: ['309988001', '309989009'], department_ids: ['485396012', '486546481', '225738002', '225746001'] },
    # Lab Technician
    # Oph
    { id: BSON::ObjectId('58b6d7b25e751b4f33110ad7'), salutation: 'Mr', fullname: 'HOSPB OPHA', designation: 'Oph Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@opha.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_opha',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [2822900478], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309935007'] },
    { id: BSON::ObjectId('58b6d7b35e751b4f33110ad8'), salutation: 'Ms', fullname: 'HOSPB OPHB', designation: 'Oph Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@ophb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_ophb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [2822900478], department_id: '309988001', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309935007'] },
    # Lab
    { id: BSON::ObjectId('58b6d7b35e751b4f33110ad9'), salutation: 'Mr', fullname: 'HOSPB LABA', designation: 'Lab Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@laba.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_laba',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159282002], department_id: '261904005', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['261904005'] },
    { id: BSON::ObjectId('58b6d7b45e751b4f33110ada'), salutation: 'Ms', fullname: 'HOSPB LABB', designation: 'Lab Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@labb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_labb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [159282002], department_id: '261904005', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['261904005'] },
    # Rad
    { id: BSON::ObjectId('58b6d7b45e751b4f33110adb'), salutation: 'Mr', fullname: 'HOSPB RADA', designation: 'Rad Tech',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@rada.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_rada',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [41904004], department_id: '309964003', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309964003'] },
    { id: BSON::ObjectId('58b6d7b55e751b4f33110adc'), salutation: 'Ms', fullname: 'HOSPB RADB', designation: 'Rad Tech',
      gender: 'Female', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@radb.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_radb',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/investigation_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [41904004], department_id: '309964003', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['309964003'] },
    # TPA
    { id: BSON::ObjectId('58b6d7b65e751b4f33110ade'), salutation: 'Mr', fullname: 'HOSPB TPA', designation: 'TPA',
      gender: 'Male', dob: user_dob, age: Faker::Number.number(2), mobilenumber: Faker::Number.number(10), email: 'hospb@tpa.com',
      employee_id: "emp_#{SecureRandom.hex(3)}", telephone: Faker::Number.number(10), address: Faker::Address.street_address, country_id: 'IN_108', city: 'Bengaluru',
      state: 'KARNATAKA', pincode: '560102', educational_qual: [''], work_exp: [''], username: 'hospb_tpa',
      alternate_email: Faker::Internet.email, alternate_telephone: Faker::Number.number(10), password: 'Health@12',
      password_confirmation: 'Health@12', password_reset_token: nil, password_reset_sent_at: nil, licence_number: nil, is_active: true,
      user_profile_pic: Faker::Avatar.image, user_selected_url: '/tpa/insurance_management', account_expiry_date: Date.current + 100.years,
      facility_ids: ['58b6b4776c55d3b8a5400a26', '58b6b47c6c55d3b8a5400a27', '58b6b5366c55d3b8a5400a28', '58b6b53b6c55d3b8a5400a29'],
      role_ids: [573021946], department_id: '450368792', organisation_id: BSON::ObjectId('58b6b43f6c55d3b8a5400a1f'),
      integration_identifier: BSON::ObjectId.new, specialty_ids: [], department_ids: ['450368792'] }
  ]
)

@organisations.each do |organisation|
  OrganisationsSetting.create!(
    [
      { organisation_id: organisation.id, visit_sms_schedule: '0', followup_sms_schedule: '0', long_overdue_sms_schedule: '0', birthday_sms_schedule: '0' }
    ]
  )

  InvoiceSetting.create!(organisation_id: organisation.id)
end

@facilities.where(:organisation_id.in => ['58b6b43a6c55d3b8a5400a1e', '58b6b43f6c55d3b8a5400a1f']).all.each do |facility|
  if facility.organisation_id.to_s == '58b6b43a6c55d3b8a5400a1e'
    Inventory::Department.create!(
      [
        { name: 'Optical Shop', display_name: 'Optical Shop', department_id: '50121007', facility_id: facility.id }
      ]
    )
  end
  Inventory::Department.create!(
    [
      { name: 'Central', display_name: 'Central', department_id: 'central', facility_id: facility.id },
      { name: 'Pharmacy Shop', display_name: 'Pharmacy Shop', department_id: '284748001', facility_id: facility.id }
    ]
  )
end

@users.each.with_index do |user, _i|
  UsersSetting.create!(
    [
      { organisation_id: user.organisation_id, user_id: user.id, visit_sms_schedule: '0', followup_sms_schedule: '0', long_overdue_sms_schedule: '0' }
    ]
  )
end

@organisations.each do |organisation|
  # creating default organisation appointment type
  OrganisationAppointmentType.create!(
    [
      { label: 'New', duration: 10, background: '#93FF33', is_active: true, is_default: true, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 1 },
      { label: 'Review', duration: 10, background: '#ff0000', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 2 },
      { label: 'Doctor Review', duration: 10, background: '#33FFD7', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 3 },
      { label: 'PMT', duration: 10, background: '#3380FF', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 4 },
      { label: 'Investigation', duration: 10, background: '#000000', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 5 },
      { label: 'Surgery', duration: 10, background: '#fbff00', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 6 },
      { label: 'LASER', duration: 10, background: '#2e00ee', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 7 },
      { label: 'Referral', duration: 10, background: '#660000', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 8 },
      { label: 'Post OP', duration: 10, background: '#FF33AC', is_active: true, is_default: false, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 9 }
    ]
  )

  # adding sub appointment category which provided by default
  OrganisationAppointmentCategoryType.create!(
    [
      { label: 'Free', background: '#EC2E06', is_active: true, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 1, provided_by: 'HG' },
      { label: 'Paid', background: '#55FF33', is_active: true, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 2, provided_by: 'HG'  },
      { label: 'Discounted', background: '#000000', is_active: true, organisation_id: organisation.id, specialty_ids: organisation.specialty_ids, default_set: true, s_no: 3, provided_by: 'HG' }
    ]
  )

  # now flowing appointment types to facility level
  organisation_appointment_type = OrganisationAppointmentType.where(organisation_id: organisation.id)

  organisation.facilities.each do |fac|
    organisation_appointment_type.each do |org_ap_type|
      AppointmentType.create!(
        label: org_ap_type.label, duration: org_ap_type.duration, background: org_ap_type.background, is_active: org_ap_type.is_active,
        is_default: org_ap_type.is_default, organisation_id: organisation.id, facility_id: fac.id, version: 'after_orange',
        organisation_appointment_type_id: org_ap_type.id, specialty_ids: fac.specialty_ids, comment: ''
      )
    end
  end
end

@facilities.all.each do |facility|
  user_setting_hash = {}
  opd_print_setting = {}
  ipd_print_setting = {}

  setting_hash = { header_height: '3', footer_height: '2', left_margin: '1', right_margin: '1', logo_location: '', header_location: '',
                   right: '', left: '', header: '', customised_letter_head: true, customised_footer: true, footer_text: '', updated: false }

  User.where(facility_ids: facility.id.to_s).each do |user|
    @user_state = UserState.new(facility_id: facility.id, user_id: user.id)
    @user_state.save

    user_setting_hash[user.id.to_s] = { sms_feature: true, personilized_sms: false, name: user.fullname, is_active: user.is_active }
    opd_print_setting[user.id.to_s] = setting_hash
    ipd_print_setting = setting_hash
  end

  FacilitySetting.create(
    facility_id: facility.id, user_sms_feature: user_setting_hash, sms_feature: true, facility_name: facility.name,
    all_print_setting: setting_hash, opd_print_setting: opd_print_setting, ipd_print_setting: ipd_print_setting,
    pharmacy_print_setting: setting_hash, optical_print_setting: setting_hash, laboratory_print_setting: setting_hash,
    radiology_print_setting: setting_hash, ophthalmology_print_setting: setting_hash, invoice_print_setting: setting_hash
  )
end
