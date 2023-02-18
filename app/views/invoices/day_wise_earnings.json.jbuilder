json.array!(@each_day_earnings) do |each_day|
  json.date each_day.date
  json.total_earnings each_day.total_earnings
end
