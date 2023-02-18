#bundle exec rake db:dump:referral_type_seed
ReferralType.delete_all

ReferralType.create!(
  [
    { id: 'FS-RT-0001', name: 'Self', label: 'self', is_manageable: false },
    { id: 'FS-RT-0002', name: 'Referring Doctor', label: 'doctor_referral' },
    { id: 'FS-RT-0003', name: 'Staff Referral', label: 'staff_referral' },
    { id: 'FS-RT-0004', name: 'Relative', label: 'relative', is_manageable: false },
    { id: 'FS-RT-0005', name: 'Campaign', label: 'campaign' },
    { id: 'FS-RT-0006', name: 'Camp', label: 'camp' },
    { id: 'FS-RT-0007', name: 'Institutional Referral', label: 'institutional_referral' },
    { id: 'FS-RT-0008', name: 'Agent', label: 'agent' },
    { id: 'FS-RT-0009', name: 'Others', label: 'others', is_manageable: false },
    { id: 'FS-RT-0010', name: 'Integration', label: 'integration', is_manageable: false, is_active: false },
    { id: 'FS-RT-0011', name: 'Online', label: 'online' },
    { id: 'FS-RT-0012', name: 'Third Party', label: 'third_party' },
    { id: 'FS-RT-0013', name: 'Consultant', label: 'consultant' }
  ]
)
