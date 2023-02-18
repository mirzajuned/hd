module PatientSummaryHelpers
  module OutpatientHelper
    def self.default_active_tab(current_user)
      {"HGP-102-110-101" => "timeline", "HGP-102-110-102" => "uploads", "HGP-102-110-103" => "medications", "HGP-102-110-104" => "investigations", "HGP-102-110-105" => "optical", "HGP-102-110-106" => "bills"}.each do |k,v|
        if Authorization::PolicyHelper.verification(current_user.id, k)
          return v
        end
      end
    end

    def self.get_last_tab(current_user)
      last_tab = ''
      {"HGP-102-110-101" => "timeline", "HGP-102-110-102" => "uploads", "HGP-102-110-103" => "medications", "HGP-102-110-104" => "investigations", "HGP-102-110-105" => "optical", "HGP-102-110-106" => "bills"}.each do |k,v|
        if Authorization::PolicyHelper.verification(current_user.id, k)
          last_tab = v
        end
      end
      last_tab
    end
  
  end
end