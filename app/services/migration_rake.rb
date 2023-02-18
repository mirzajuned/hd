class MigrationRake
  def correction_refraction_data(str)
    if str.include?("+")
      return str
    elsif str.split("/").length == 3
      data = str.split("/")
      data[0..1] = data[0..1].sort_by(&:to_i).join("/")
      data[1] = "-" + data[1][-1]
      data.join("")
    elsif (str.split(Regexp.union(['/', "-"])) - [""]).length == 1
      return str
    else
      data = str.split(Regexp.union(['/', "-"])).map { |word| Date::ABBR_MONTHNAMES.index(word) || word }
      data[0..1] = data[0..1].sort_by(&:to_i).join("/")
      return data.join("")
    end
  end
end
