# bundle exec rake db:dump:department_seed
Department.delete_all

Department.create!(
  [
    { id: '485396012', name: 'Outpatient Department', is_launched: true, display_name: 'OPD', order: 1 },
    { id: '486546481', name: 'Inpatient Department', is_launched: true, display_name: 'IPD', order: 2 },
    { id: '50121007',  name: 'Optical Department', is_launched: true, display_name: 'Optical', order: 3 },
    { id: '284748001', name: 'Pharmacy Department', is_launched: true, display_name: 'Pharmacy', order: 4 },
    { id: '224608005', name: 'Adminstration Department', is_launched: true, display_name: 'Adminstration', order: 5 },
    { id: '225728007', name: 'Emergency Department', is_launched: true, display_name: 'Emergency', order: 6 },
    { id: '225738002', name: 'OT Department', is_launched: true, display_name: 'OT', order: 7 },
    { id: '225746001', name: 'Ward Department', is_launched: true, display_name: 'Ward', order: 8 },
    { id: '261904005', name: 'Laboratory department', is_launched: true, display_name: 'Laboratory', order: 9 },
    { id: '309935007', name: 'Ophthal Department', is_launched: true, display_name: 'Ophthal', order: 10 },
    { id: '309964003', name: 'Radiology Department', is_launched: true, display_name: 'Radiology', order: 11 },
    { id: '450368792', name: 'TPA Department', is_launched: true, display_name: 'TPA', order: 12 },
    { id: '550368792', name: 'Central Hub Department', is_launched: true, display_name: 'Central Hub', order: 13 },
    { id: '384748001', name: 'OT Store Department', is_launched: true, display_name: 'OT Store', order: 14 },
    { id: '116154003', name: 'Patient Department', is_launched: true, display_name: 'Patient', order: 15 },
    { id: '384748002', name: 'Marketing Department', is_launched: true, display_name: 'Marketing', order: 16 },
    { id: '384748003', name: 'Stationery Department', is_launched: true, display_name: 'Stationery', order: 17 },
    { id: '384748004', name: 'House Keeping Department', is_launched: true, display_name: 'House Keeping', order: 18 },
    { id: '384748005', name: 'Maintenance Department', is_launched: true, display_name: 'Maintenance', order: 19 },
    { id: '334046963', name: 'Central', is_launched: true, display_name: 'Central', order: 20 }
  ]
)
