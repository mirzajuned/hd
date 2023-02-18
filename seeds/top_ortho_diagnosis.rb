# # bundle exec rake db:dump:top_ortho_diagnosis RAILS_ENV=development
# require 'csv'
# array = ["elbow.csv","footankle.csv","hip.csv","knee.csv","shoulder.csv","spine.csv","wrist.csv"]
# finalarray = []
# array.each do |ar|
#   csv_text = File.read(Rails.root.join('public', ar)).scrub
#   arr = []
#   csv = CSV.parse(csv_text, :headers => true)
#   csv.each do |row|
#     code = row['code']
#     arr << "#{code}".slice(0,3).downcase
#   end
#   first =  arr.uniq
#   #code from website
#   second = ["m12","m15","m16","m17","m19","m20","m21","m23","m24","m25","m40","m41","m43","m47","m48","m50","m51","m53","m54","m65","m66","m75","m76","m79","m80","m84","m86","m87","s12","s32","s42","s43","s46","s52","s72","s82","s83","s92","s93","t84","d21","e10","e11","g56","q76"]
#   array =  first & second
#   hash = Hash.new
#   hash['specialty_id'] = 309989009
#   hash['name'] = ar.split(".")[0]
#   list = []
#   array.each do |icd|
#     hash1 = Hash.new()
#     hash1['code'] = FullIcd.find_by(code:icd)[:code].capitalize
#     hash1['name'] = FullIcd.find_by(code:icd)[:originalname]
#     list << hash1
#   end
#   hash['list'] = list
#   finalarray << hash
# end
# puts finalarray
