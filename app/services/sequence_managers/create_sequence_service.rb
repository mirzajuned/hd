class SequenceManagers::CreateSequenceService
  $module_hash = { 
                  'invoice' => {
                    original_counter: 200001,
                    abbreviation: 'INV',
                    display_name: 'Bill Number',
                    organisation_module: 'invoice',
                    department_ids: ['485396012', '486546481', '50121007', '284748001']
                  },
                  'advance_payment' => {
                    original_counter: 10001,
                    abbreviation: 'ADV',
                    display_name: 'Advance Display ID',
                    organisation_module: 'advance',
                    department_ids: ['485396012', '486546481', '50121007', '284748001']
                  },
                  'refund_payment' => {
                    original_counter: 10001,
                    abbreviation: 'RFD',
                    display_name: 'Refund Display ID',
                    organisation_module: 'refund',
                    department_ids: ['485396012', '486546481', '50121007', '284748001']
                  },
                  'patient' => {
                    original_counter: 100001,
                    abbreviation: 'PAT',
                    display_name: 'Patient Display ID',
                    organisation_module: 'patient',
                  },
                  'appointment' => {
                    original_counter: 200001,
                    abbreviation: 'OPD',
                    display_name: 'Appointment ID',
                    organisation_module: 'opd',
                    department_ids: ['485396012']
                  },
                  'admission' => {
                    original_counter: 200001,
                    abbreviation: 'IPD',
                    display_name: 'Admission ID',
                    organisation_module: 'ipd',
                    department_ids: ['486546481']
                  },
                  'case_sheet' => {
                    original_counter: 1000001,
                    abbreviation: 'CS',
                    display_name: 'CaseSheet ID',
                    organisation_module: 'case',
                  },
                  'sales_order' => {
                    original_counter: 1000001,
                    abbreviation: 'SO',
                    display_name: 'Order Number',
                    organisation_module: 'sales_order',
                    department_ids: ['50121007', '284748001']
                  },
                  'indent_order' => {
                    original_counter: 100001,
                    abbreviation: 'INDT',
                    display_name: 'Indent Order',
                    organisation_module: 'indent_order',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  },
                  'son_transaction' => {
                    original_counter: 100001,
                    abbreviation: 'OP',
                    display_name: 'SON',
                    organisation_module: 'opening_stock',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  },
                  'purchase_return_transaction' => {
                    original_counter: 100001,
                    abbreviation: 'GRDN',
                    display_name: 'Purchase Return',
                    organisation_module: 'purchase_return_transaction',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  },
                  'purchase_transaction' => {
                    original_counter: 100001,
                    abbreviation: 'GRN',
                    display_name: 'Purchase',
                    organisation_module: 'purchase_transaction',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  },
                  'srn' => {
                    original_counter: 100001,
                    abbreviation: 'SRN',
                    display_name: 'SRN',
                    organisation_module: 'srn',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  },
                  'stock_adjustment' => {
                    original_counter: 100001,
                    abbreviation: 'ADJ',
                    display_name: 'Adjustment',
                    organisation_module: 'stock_adjustment',
                    has_entity: true,
                    has_date: true,
                    department_ids: ['384748001', '550368792', '50121007', '284748001', '384748004', '384748005', '384748002', '384748003', '334046963']
                  }
                }

  $display_format = 'organisation_abbreviation,-,module_prefix,-,organisation_counter'
  $display_date_format = 'organisation_abbreviation,-,module_prefix,-,has_date,-,organisation_counter'

  class << self
    def call(organisation_id, modulehash = {})
      is_primary = true
      counter_level = 'organisation'
      organisation = Organisation.find_by(id: organisation_id)
      organisation_abbreviation = organisation.try(:identifier_prefix)
      prefix_level = 'other'
      if modulehash.present?
        modulehash.each_key do |module_name|
          SequenceManagers::CreateSequenceDetailsService.call(is_primary, counter_level, organisation_id, prefix_level, modulehash, module_name)
        end
      else
        $module_hash.each_key do |module_name|
          SequenceManagers::CreateSequenceDetailsService.call(is_primary, counter_level, organisation_id, prefix_level, $module_hash, module_name)
        end
      end
    end
    # EOF call
  end
end
