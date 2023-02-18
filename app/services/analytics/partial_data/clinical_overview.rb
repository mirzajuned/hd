module Analytics::PartialData
  class ClinicalOverview
    def self.total_diagnosis_count(params_hash = {})
      label_on = params_hash['label_on']
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id
      user_id = user_id.present? && (user_id.is_a? String) ? BSON::ObjectId(user_id) : user_id

      # if from_date == to_date
      #   from_date = from_date - 7.days
      # end
      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id
      }
      match_with_this.except!('user_id') unless user_id.present?
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'

      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }

      diagnoses_data = Analytics::ClinicalDataOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          },
          {
            '$project' => {
              'total_diagnosis' => { '$sum' => '$diagnoses_list.count' },
              'total_procedure' => { '$sum' => '$procedures_list.count' },
              'total_ophthal_investigations_list' => { '$sum' => '$ophthal_investigations_list.count' },
              'total_laboratory_investigations_list' => { '$sum' => '$laboratory_investigations_list.count' },
              'total_radiology_investigations_list_data' => { '$sum' => '$radiology_investigations_list.count' }
            }
          }
        ]
      ).to_a

      total_diagnosis = diagnoses_data.pluck(:total_diagnosis).reject(&:blank?).sum
      total_procedure = diagnoses_data.pluck(:total_procedure).reject(&:blank?).sum
      total_ophthal_investigations_list = diagnoses_data.pluck(:total_ophthal_investigations_list).reject(&:blank?).sum
      total_laboratory_investigations_list = diagnoses_data.pluck(:total_laboratory_investigations_list).reject(&:blank?).sum
      total_radiology_investigations_list = diagnoses_data.pluck(:total_radiology_investigations_list_data).reject(&:blank?).sum

      [total_diagnosis, total_procedure, total_ophthal_investigations_list, total_laboratory_investigations_list, total_radiology_investigations_list]
    end

    def self.fetch_params_hash(params_hash = {})
      organisation_id = params_hash['organisation_id']
      facility_id = params_hash['facility_id']
      specialty_id = params_hash['specialty_id']
      from_date = params_hash['analytics_from_date']
      to_date = params_hash['analytics_to_date']

      [organisation_id, facility_id, specialty_id, from_date, to_date]
    end

    def self.filter_group_by(from_date, to_date, label_on)
      from_date = Date.parse(from_date)
      to_date = Date.parse(to_date)

      group_by = case label_on
                 when 'days'
                   '$dayOfMonth'
                 when 'weeks'
                   '$week'
                 when 'months'
                   '$month'
                 else
                   '$year'
                 end

      [group_by, from_date, to_date]
    end
  end
end
