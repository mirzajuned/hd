class PatientSearch
  include Mongoid::Document
  include Mongoid::Attributes::Dynamic
  include Mongoid::Timestamps

  # include Elasticsearch::Model
  # include Elasticsearch::Model::Callbacks

  searchkick word_middle: [:patient_name_search, :mr_no_search, :patient_identifier_id], callbacks: :async

  def search_data
    {
      patient_name_search: patient_name.tr('^A-Za-z0-9', ' ').downcase,
      mr_no_search: mr_no_search.to_s,
      mobile_number: mobile_number.to_s,
      patient_identifier_id_search: patient_identifier_id_search,
      patient_identifier_id: patient_identifier_id.to_s.tr('^A-Za-z0-9', '').try(:downcase),
      reg_hosp_ids: reg_hosp_ids
    }
  end

  field :search, type: String
  field :patient_name, type: String
  field :patient_id, type: BSON::ObjectId
  field :mobile_number, type: Integer
  field :patient_identifier_id, type: String
  field :mr_no, type: String
  field :patient_identifier_id_search, type: String
  field :mr_no_search, type: String
  field :patient_name_search, type: String
  field :reg_hosp_ids, type: Array

  # Indexing Collection
  # db.patient_searches.createIndex( { reg_hosp_ids: 1, search: 1 } )

  # Winning Plan
  # db.patient_searches.explain().find({reg_hosp_ids: '58419458f9c44c36f20001e0', search: /PAT/i})

  # def as_indexed_json(options={})
  #   as_json(except: [:id, :_id])
  # end
end
