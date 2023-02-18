class OtherInvestigationData
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps
end

################### ACTIVE RECORD CODE COMMENTED #############################################3
# class OtherInvestigationData < ActiveRecord::Base
#   self.table_name = :other_investigations
#   self.primary_key = :investigation_id
# end
