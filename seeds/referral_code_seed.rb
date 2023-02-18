# bundle exec rake db:dump:referral_code_seed RAILS_ENV=development
ReferralCode.delete_all

ReferralCode.create!(
  [
    { code: 'hg_expired', new_users_limit: 0, referring_user: 'HG Expired', free_trial_period: 30, code_expiry_date: Date.yesterday, code_release_date: Date.parse('05/02/2018'), use_limit: 10000 },
    { code: '218HGI3030', new_users_limit: 0, referring_user: 'HG Internal', free_trial_period: 30, code_expiry_date: Date.parse('15/03/2118'), code_release_date: Date.parse('16/02/2018'), use_limit: 10000 },
    { code: '218OPH1153', new_users_limit: 0, referring_user: 'Dr.Tamilarasan Senthil', free_trial_period: 30, code_expiry_date: Date.parse('15/03/2018'), code_release_date: Date.parse('05/02/2018'), use_limit: 10000 },
    { code: '218OPH2153', new_users_limit: 0, referring_user: 'Dr.Tamilarasan Senthil', free_trial_period: 30, code_expiry_date: Date.parse('15/03/2018'), code_release_date: Date.parse('05/02/2018'), use_limit: 10000 },
    { code: '218OPH3153', new_users_limit: 0, referring_user: 'Dr.Tamilarasan Senthil', free_trial_period: 30, code_expiry_date: Date.parse('15/03/2018'), code_release_date: Date.parse('05/02/2018'), use_limit: 10000 }
  ]
)
