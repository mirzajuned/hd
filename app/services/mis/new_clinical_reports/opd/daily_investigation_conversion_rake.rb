# bundle exec rake clinical:investigation_report\['2021-04-01','2021-04-15'\] RAILS_ENV=development
module Mis::NewClinicalReports::Opd
  class DailyInvestigationConversionRake
    class << self
      def call(start_date, end_date, org_id = nil)
        @start_date = start_date
        @end_date = end_date
        @org_id = BSON::ObjectId org_id
        @facilities = Organisation.find_by(id: @org_id)&.facilities || []
        import
      end

      private

      def import
      	@facilities.each do |facility|
      	  (@start_date.to_date..@end_date.to_date).each do |date|
      	    adv_query = query(facility.id, 'advised', date)
      	    perf_query = query(facility.id, 'performed', date)
      	    advised_invs = Investigation::InvestigationDetail.collection.aggregate(adv_query).to_a
      	    performed_invs = Investigation::InvestigationDetail.collection.aggregate(perf_query).to_a
      	    invs = advised_invs + performed_invs
      	    investigations(invs, date, facility.id)
      	  end
      	end
      end

      def investigations(invs, date, facility_id)
      	collection = invs.group_by { |data| data[:_id][:investigation_id]}
      	collection.each do |id, inv|
          inv_conv = MisClinical::Opd::DailyInvestigationConversion
                    .find_or_create_by(investigation_id: id, investigation_date: date, facility_id: facility_id, organisation_id: @org_id)
          inv_conv.investigation_name = inv[0][:investigation_name]
          inv_conv.investigation_type = inv[0][:_type].split('::').last
          inv_conv.total_advised = (inv.detect { |i| i[:total_advised]} || {total_advised: 0})[:total_advised]
          inv_conv.total_performed = (inv.detect { |i| i[:total_performed]} || {total_performed: 0})[:total_performed]
          inv_conv.investigation_specialization = inv[0][:specialization]
          inv_conv.save!
      	end
      end

      def query(facility_id, type, date)
        match_options = { "#{type}_at": { '$gte' => date.beginning_of_day, '$lte' => date.end_of_day } }
        match_options = match_options.merge({ facility_id: facility_id, organisation_id: @org_id })
        match_options[:is_deleted] = false
        aggregation_query = [
          { "$match": match_options },
          { "$group": group_options(type) }
        ]
      end

      def group_options(type)
      	{ 
      	  _id: { investigation_id: '$investigation_id', investigation_name: '$investigation_name'}, 
      	  investigation_name: {'$first': '$name'},
      	  specialization: { '$first': '$specialization' },
      	  "total_#{type}": { "$sum": 1 },
          _type: { '$first': '$_type' },
      	  "#{type}": { '$first': true }
      	}
      end

    end
  end
end