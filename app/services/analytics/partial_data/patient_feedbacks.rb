module Analytics::PartialData
  class PatientFeedbacks
    include AnalyticsHelper
    def self.overall_rating(params_hash = {})
      label_on = params_hash["label_on"]

      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      from_date, to_date = set_initial_params(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != "all" ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        "organisation_id" => organisation_id,
        "facility_id" => facility_id,
      }
      match_with_this2 = params_hash["data_query"].delete_if { |k| k == {} }
      match_with_this.except!("facility_id") if facility_id == "all"

      feedback_data = Analytics::PatientFeedback.collection.aggregate([
                                                                        {
                                                                          "$match" => match_with_this,
                                                                        }, {
                                                                          "$match" => { "$or" => match_with_this2 }
                                                                        },
                                                                        {
                                                                          "$group" => {
                                                                            "_id" => "null",
                                                                            "usability" => { "$sum" => "$usability" },
                                                                            "waiting" => { "$sum" => "$waiting" },
                                                                            "cleanliness" => { "$sum" => "$cleanliness" },
                                                                            "overallcare" => { "$sum" => "$overallcare" },
                                                                            "recommendation" => { "$sum" => "$recommendation" },
                                                                            "average_rating" => { "$sum" => "$average_rating" },
                                                                            "total_counts" => { "$sum" => "$total_count" }
                                                                          }
                                                                        }
                                                                      ]).to_a

      feedback_labels = ["usability", "waiting", "cleanliness", "overallcare", "recommendation", "average_rating"]
      data_array = []
      counter = feedback_data.present? ? feedback_data[0]["total_counts"] : 1
      feedback_labels.each do |lab|
        feedback_data.present? && feedback_data[0].present? && feedback_data[0][lab] ? data_array.push((feedback_data[0][lab].to_f / counter)) : data_array.push(0)
      end

      return feedback_labels, data_array
    end

    def self.each_facility_rating(params_hash = {})
      label_on = params_hash["label_on"]
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != "all" ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        "organisation_id" => organisation_id,
        "facility_id" => facility_id,
      }
      match_with_this2 = params_hash["data_query"].delete_if { |k| k == {} }
      match_with_this.except!("facility_id") if facility_id == "all"

      facility_feedback = Analytics::PatientFeedback.collection.aggregate([
                                                                            {
                                                                              "$match" => match_with_this,
                                                                            }, {
                                                                              "$match" => { "$or" => match_with_this2 }
                                                                            },
                                                                            { "$group" => { "_id" => "$facility_id",
                                                                                            "usability" => { "$sum" => "$usability" },
                                                                                            "waiting" => { "$sum" => "$waiting" },
                                                                                            "cleanliness" => { "$sum" => "$cleanliness" },
                                                                                            "overallcare" => { "$sum" => "$overallcare" },
                                                                                            "recommendation" => { "$sum" => "$recommendation" },
                                                                                            "average_rating" => { "$sum" => "$average_rating" },
                                                                                            "total_counts" => { "$sum" => "$total_count" } } }, {
                                                                                              "$project" => { "_id" => "$_id",
                                                                                                              "usability" => { "$divide" => ["$usability", "$total_counts"] },
                                                                                                              "waiting" => { '$divide' => ["$waiting", '$total_counts'] },
                                                                                                              "cleanliness" => { '$divide' => ["$cleanliness", '$total_counts'] },
                                                                                                              "overallcare" => { '$divide' => ["$overallcare", '$total_counts'] },
                                                                                                              "recommendation" => { '$divide' => ["$recommendation", '$total_counts'] },
                                                                                                              "average_rating" => { '$divide' => ["$average_rating", '$total_counts'] }, }
                                                                                            }

                                                                          ]).to_a

      facility_feedback_label = []
      facility_feedback_data  = []
      facility_ids = []
      feedback_labels = ["usability", "waiting", "cleanliness", "overallcare", "recommendation", "average_rating"]
      chart_colors = ["#82ccdd", "#fed156", "#1B9CFC", "#58B19F", "#3e21ad", "#008080", '#bcf60c', '#fabebe', '#008080', '#e6beff', '#9a6324', '#fffac8', '#800000']
      if facility_feedback.present?
        usability_data = facility_feedback.pluck(:usability).map { |a| a.round(2) }
        waiting_data = facility_feedback.pluck(:waiting).map { |a| a.round(2) }
        cleanliness_data = facility_feedback.pluck(:cleanliness).map { |a| a.round(2) }
        overallcare_data = facility_feedback.pluck(:overallcare).map { |a| a.round(2) }
        recommendation_data = facility_feedback.pluck(:recommendation).map { |a| a.round(2) }
        average_rating_data = facility_feedback.pluck(:average_rating).map { |a| a.round(2) }

        feedback_labels.each_with_index do |lab, indx|
          hashed = Hash.new
          hashed['label'] = lab.to_s.titleize
          hashed['backgroundColor'] = chart_colors[indx]
          hashed['data'] = eval("#{lab}_data")
          facility_feedback_data.push(hashed)
        end
        facility_feedback.each do |data|
          facility = Facility.find_by(id: data["_id"])
          facility_feedback_label.push(facility.try(:abbreviation))
        end

      end

      return facility_feedback_label, facility_feedback_data
    end

    def self.organisation_level_rating(params_hash = {})
      label_on = params_hash["label_on"]
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != "all" ? BSON::ObjectId(facility_id) : facility_id

      match_with_this = {
        "organisation_id" => organisation_id,
        "facility_id" => facility_id,
      }
      match_with_this2 = params_hash["data_query"].delete_if { |k| k == {} }
      match_with_this.except!("facility_id") if facility_id == "all"

      organisation_data = Analytics::PatientFeedback.collection.aggregate([
                                                                            {
                                                                              "$match" => match_with_this,
                                                                            }, {
                                                                              "$match" => { "$or" => match_with_this2 }
                                                                            },
                                                                            { "$group" => {
                                                                              "_id" => "null",
                                                                              "usability" => { "$sum" => "$usability" },
                                                                              "waiting" => { "$sum" => "$waiting" },
                                                                              "cleanliness" => { "$sum" => "$cleanliness" },
                                                                              "overallcare" => { "$sum" => "$overallcare" },
                                                                              "recommendation" => { "$sum" => "$recommendation" },
                                                                              "average_rating" => { "$sum" => "$average_rating" },
                                                                              "total_counts" => { "$sum" => "$total_count" }
                                                                            } }, {
                                                                              "$project" => {
                                                                                "_id" => "$_id",
                                                                                "usability" => { "$divide" => ["$usability", "$total_counts"] },
                                                                                "waiting" => { "$divide" => ["$waiting", "$total_counts"] },
                                                                                "cleanliness" => { "$divide" => ["$cleanliness", "$total_counts"] },
                                                                                "overallcare" => { "$divide" => ["$overallcare", "$total_counts"] },
                                                                                "recommendation" => { "$divide" => ["$recommendation", "$total_counts"] },
                                                                                "average_rating" => { "$divide" => ["$average_rating", "$total_counts"] },
                                                                              }
                                                                            }

                                                                          ]).to_a.first

      feedback_labels = ["usability", "waiting", "cleanliness", "overallcare", "recommendation", "average_rating"]
      data_array = []
      if organisation_data.present?
        feedback_labels.each_with_index do |lab, ind|
          data_array.push(organisation_data[lab])
        end
      end

      return feedback_labels, data_array.map { |d| d.round(2) }
    end

    def self.overall_organisation_rating(params_hash = {})
      label_on = params_hash["label_on"]
      organisation_id, facility_id, from_date, to_date = fetch_params_hash(params_hash)
      group_by, from_date, to_date = set_initial_params(from_date, to_date, label_on)

      organisation_id = BSON::ObjectId(organisation_id.to_s)
      facility_id     = (facility_id.is_a? String) && facility_id != "all" ? BSON::ObjectId(facility_id) : facility_id
      if from_date == to_date
        from_date = from_date - 7
      end

      match_with_this = {
        "organisation_id" => organisation_id,
        "facility_id" => facility_id,
      }
      match_with_this2 = params_hash["data_query"].delete_if { |k| k == {} }
      match_with_this.except!("facility_id") if facility_id == "all"

      organisation_data = Analytics::PatientFeedback.collection.aggregate([
                                                                            { "$match" => match_with_this, }, {
                                                                              "$match" => { "$or" => match_with_this2 }
                                                                            }, {
                                                                              "$sort" => { "start_date": -1 }
                                                                            }, {
                                                                              "$project" => {
                                                                                "start_date" => "$start_date",
                                                                                "end_date" => "$end_date",
                                                                                "usability" => 1,
                                                                                "waiting" => 1,
                                                                                "cleanliness" => 1,
                                                                                "overallcare" => 1,
                                                                                "recommendation" => 1,
                                                                                "average_rating" => 1,
                                                                                "total_count" => 1,
                                                                                "facility_id" => 1,
                                                                              }
                                                                            }, {
                                                                              "$group" => {
                                                                                "_id" => { "#{group_by}" => "$start_date" },
                                                                                "usability" => { "$sum" => "$usability" },
                                                                                "waiting" => { "$sum" => "$waiting" },
                                                                                "cleanliness" => { "$sum" => "$cleanliness" },
                                                                                "overallcare" => { "$sum" => "$overallcare" },
                                                                                "recommendation" => { "$sum" => "$recommendation" },
                                                                                "average_rating" => { "$sum" => "$average_rating" },
                                                                                "total_counts" => { "$sum" => "$total_count" },
                                                                                "start_date" => { "$addToSet" => "$start_date" },
                                                                                "end_date" => { "$addToSet" => "$end_date" }
                                                                              }
                                                                            }, {
                                                                              "$project" => {
                                                                                "total_count" => 1,
                                                                                "usability" => { "$divide" => ["$usability", "$total_counts"] },
                                                                                "waiting" => { "$divide" => ["$waiting", "$total_counts"] },
                                                                                "cleanliness" => { "$divide" => ["$cleanliness", "$total_counts"] },
                                                                                "overallcare" => { "$divide" => ["$overallcare", "$total_counts"] },
                                                                                "recommendation" => { "$divide" => ["$recommendation", "$total_counts"] },
                                                                                "average_rating" => { "$divide" => ["$average_rating", "$total_counts"] },
                                                                                "start_date" => 1,
                                                                                "end_date" => 1
                                                                              }
                                                                            }, {
                                                                              "$project" => {
                                                                                "_id" => 1,
                                                                                "total_rating" => {
                                                                                  "$divide" => [
                                                                                    {
                                                                                      "$add" => ["$usability", "$waiting", "$cleanliness", "$overallcare", "$recommendation", "$average_rating"]
                                                                                    }, 6
                                                                                  ]
                                                                                },
                                                                                "start_date" => 1,
                                                                                "end_date" => 1
                                                                              }
                                                                            },
                                                                            {
                                                                              "$sort" => { "start_date": -1 }
                                                                            }
                                                                          ]).to_a

      data_labels = []
      org_feedback_data = []
      organisation_data = organisation_data.reverse
      if organisation_data.present?
        if group_by == "$dayOfMonth"
          organisation_data = (from_date).upto(to_date).to_a.map { |date| (organisation_data.find { |set| set["_id"].to_i == date.strftime("%d").to_i }) || {} }
          organisation_data.each_with_index do |row, indx|
            if row.present?
              data_labels.push(row["start_date"][0].strftime("%d %a"))
              org_feedback_data.push(row["total_rating"])
            else
              data_labels.push("")
              org_feedback_data.push(0)
            end
          end
        elsif group_by == "$week"
          organisation_data = organisation_data.each { |set| set["_id"] = set["_id"].to_i + 1 }
          organisation_data.each_with_index do |row, indx|
            start_date, end_date = row["start_date"][0], row["end_date"][0]
            data_labels << "#{start_date.strftime("%d %b")}-#{end_date.strftime("%d %b")}"
            if row.present?
              org_feedback_data.push(row["total_rating"].round(2))
            else
              org_feedback_data.push(0)
            end
          end
        elsif group_by == "$month"
          organisation_data.each_with_index do |row, indx|
            if row.present?
              data_labels.push(row["start_date"][0].strftime("%b %Y"))
              org_feedback_data.push(row["total_rating"].round(2))
            else
              data_labels.push("")
              org_feedback_data.push(0)
            end
          end
        elsif group_by == "$year"
          organisation_data.each_with_index do |row, indx|
            if row.present?
              data_labels.push(row["start_date"][0].strftime("%Y"))
              org_feedback_data.push(row["total_rating"].round(2))
            else
              data_labels.push("")
              org_feedback_data.push(0)
            end
          end
        end
      end

      return data_labels, org_feedback_data
    end

    private

    def self.fetch_params_hash(params_hash = {})
      organisation_id = params_hash["organisation_id"]
      facility_id     = params_hash["facility_id"]
      from_date = params_hash["analytics_from_date"]
      to_date = params_hash["analytics_to_date"]

      return organisation_id, facility_id, from_date, to_date
    end

    def self.set_initial_params(from_date, to_date, label_on)
      from_date = Date.parse(from_date)
      to_date = Date.parse(to_date)
      case label_on
      when "days"
        group_by = "$dayOfMonth"
      when "weeks"
        group_by = "$week"
      when "months"
        group_by = "$month"
      else
        group_by = "$year"
      end
      return group_by, from_date, to_date
    end
  end
end
