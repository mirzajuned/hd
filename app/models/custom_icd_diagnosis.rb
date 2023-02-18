class CustomIcdDiagnosis
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  field :icd_type, type: String, default: :CustomIcdDiagnosis
  field :is_deleted, type: Boolean, default: false
  field :is_attached, type: Boolean, default: false
  field :organisation_id, type: BSON::ObjectId
  field :code, type: String
  field :shortcode, type: String # in case icd is children
  field :separatedcode, type: String # in case icd is children
  field :codelength, type: Integer
  field :abbrevated_name, type: String  # from full icd
  field :fullname, type: String         # we will show this on search
  field :originalname, type: String # we will show this on search
  field :shortname, type: String        # unless it is three digit we will save (fullname - parentname and so on..)
  field :root, type: Integer            # 0 if icd is root

  field :has_parent, type: Boolean
  field :parentcodename, type: Array    # consist of [[childrenshortname-1,childrencode-1.to_s],[childrenshortname-2,childrencode.to_s-2],[...]] (to show in the drop down)
  field :parentfullinfo, type: Array    # consist of ["{"+childrensize+":"+ [childrencode.to_s, childrenname, childrenabbname ]+"}"]

  field :has_children, type: Boolean
  field :childrenfullinfo, type: Array
  field :childrencodename, type: Array

  field :has_laterality, type: Boolean
  field :laterality_position, type: String
  field :lateralitylabel, type: String

  field :children_has_laterality, type: Boolean  # usefull in case of filters/facets
  field :laterality_filter, type: Array          # usefull in case of filters/facets

  field :originatingcodes, type: Array

  field :specialty_id, type: String
  field :is_migrated, type: Boolean, default: true
end
