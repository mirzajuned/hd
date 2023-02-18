module Analytics::PartialData
  class OpdRevisitPatient
    def self.call(params_hash = {})
      label_on =  params_hash['label_on']
      organisation_id, facility_id, specialty_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = filter_group_by(from_date, to_date, label_on)
      user_id = params_hash['user_id']
      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != 'all' ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        'organisation_id' => organisation_id,
        'facility_id' => facility_id,
        'specialty_id' => specialty_id,
        'user_id' => user_id
      }
      match_with_this2 = params_hash['data_query'].delete_if { |k| k == {} }
      match_with_this.except!('facility_id') if facility_id == 'all'
      match_with_this.except!('specialty_id') if specialty_id == 'all'
      match_with_this.except!('user_id') unless user_id.present?

      general_overview_data = Analytics::GeneralOverview.collection.aggregate(
        [
          {
            '$match' => match_with_this
          }, {
            '$match' => { '$or' => match_with_this2 }
          }, {
            '$group' => {
              '_id' => 'null',
              'first_opd_visit' => { '$sum' => '$first_opd_visit' },
              'second_opd_visit' => { '$sum' => '$second_opd_visit' },
              'third_opd_visit' => { '$sum' => '$third_opd_visit' },
              'fourth_opd_visit' => { '$sum' => '$fourth_opd_visit' },
              'fifth_opd_visit' => { '$sum' => '$fifth_opd_visit' },
              'above_fifth_opd_visit' => { '$sum' => '$above_fifth_opd_visit' }
            }
          }

        ]
      ).to_a

      first_opd_visit = general_overview_data.pluck(:first_opd_visit).sum
      second_opd_visit = general_overview_data.pluck(:second_opd_visit).sum
      third_opd_visit = general_overview_data.pluck(:third_opd_visit).sum
      fourth_opd_visit = general_overview_data.pluck(:fourth_opd_visit).sum
      fifth_opd_visit = general_overview_data.pluck(:fifth_opd_visit).sum
      above_fifth_opd_visit = general_overview_data.pluck(:above_fifth_opd_visit).sum

      frequency_of_opd_revisits_data = [first_opd_visit, second_opd_visit, third_opd_visit, fourth_opd_visit, fifth_opd_visit, above_fifth_opd_visit]

      frequency_of_opd_revisits_data
    end

    private

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
