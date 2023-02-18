class RadiologyInvestigationData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
end

################### ACTIVE RECORD CODE COMMENTED #############################################3
# class RadiologyInvestigationData < ActiveRecord::Base
# self.table_name = :radiology_investigations
# self.primary_key = :investigation_id
# end
