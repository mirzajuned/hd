module MedicineCountHelper
  def pharmacy_item_count(med)
    if med[:medicinetype] == "Tablets" || med[:medicinetype] == "TAB"
      # Quantity
      if med[:medicinequantity] == "1/2"
        quantity = 0.5
      elsif med[:medicinequantity] == "1/4"
        quantity = 0.25
      else
        quantity = med[:medicinequantity].to_i
      end

      # Frequency
      if med[:medicinefrequency] == "once a month"
        frequency = 0.033333 # 1/30
      elsif med[:medicinefrequency] == "once a week"
        frequency = 0.142857 # 1/7
      elsif med[:medicinefrequency] == "Sat-Sun"
        frequency = 2
      elsif med[:medicinefrequency] == ""
        frequency = 1
      else
        frequency = med[:medicinefrequency].split("-").map { |i| i.to_i }.sum()
      end
      # Duration
      if med[:medicineduration] == ""
        duration = 1
      else
        duration = med[:medicineduration]
      end
      # DurationOption
      if med[:medicinedurationoption] == "W"
        durationoption = 7
      elsif med[:medicinedurationoption] == "M"
        durationoption = 30
      elsif med[:medicinedurationoption] == "D"
        durationoption = 1
      elsif med[:medicinedurationoption] == ""
        durationoption = 1
      else
        durationoption = 5
      end
      # Total Units
      puts quantity
      total_units = quantity * frequency * durationoption * duration.to_i
    else
      total_units = 1
    end

    total_units
  end
end
