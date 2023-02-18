# bundle exec rake db:dump:full_icd_convertor RAILS_ENV=development
require 'csv'

csv_text = File.read(Rails.root.join('public', 'icd10_comma_saperated.csv'))

csv = CSV.parse(csv_text, :headers => true)
csv.each do |row|
  t = FullIcd.new
  t.code = row['code'].downcase
  t.root = row['root']
  t.abbrevated_name = row['abbrevated_name'].tr('^A-Za-z0-9', ' ').gsub("  ", " ").downcase
  t.fullname = row['fullname'].tr('^A-Za-z0-9', ' ').gsub("  ", " ").downcase
  t.originalname = row['fullname']
  t.save
end

puts "There are now #{FullIcd.count} rows in the transactions table"
