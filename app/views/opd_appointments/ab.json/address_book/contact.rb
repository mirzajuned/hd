class Contact
  def initialize
    @phone_number = []
  end

  def add_phone_number(kind, number)
    @phone_number.push << { "#{kind}": number }
  end

  def print_phonr
    @phone_number.each do |phone|
      "#{phone[:home]}: #{phone[:number]}"
    end
  end
end

phone = Contact.new
phone.add_phone_number("Home", "9816324927")

puts phone.print_phonr
