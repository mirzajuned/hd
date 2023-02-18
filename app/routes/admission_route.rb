class AdmissionRoute
  def self.matches?(request)
    admission_day = request.params[:admission_day]
    admission_day.eql?('today') || admission_day.eql?(Date.parse(admission_day, '%d-%B-%Y').strftime('%d-%B-%Y'))
  end
end
