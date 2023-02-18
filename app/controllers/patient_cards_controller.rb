class PatientCardsController < ApplicationController
  before_action :authorize

  def print
    @patient = Patient.find_by(id: params[:patient_id])
    @organisation_id = current_facility.organisation_id.to_s
    respond_to do |format|
      if @organisation_id == '5d4a86e6cd29ba7694f4e75d'
        format.pdf { render :template => "patient_cards/print_id_card", :pdf => "Patient Card", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", page_height: 150, page_width: 150, orientation: 'Landscape', :disable_smart_shrinking => true, :show_as_html => params[:debug].present?, :header => { :spacing => 4 }, :footer => { :spacing => 10 } }
      # 2x4 custom 50 fits perfect
      elsif @organisation_id == '63c0fba8c0f92c13d714deca'
        format.pdf { render :template => "patient_cards/print_card", :pdf => "Patient Card", :layout => 'pdfgen.html.erb', viewport_size: '1280x1024', :page_size => "A4", page_height: 54, page_width: 86, orientation: 'portrait', :disable_smart_shrinking => false, :show_as_html => params[:debug].present?, :header => { :spacing => 0 }, :footer => { :spacing => 0 }, margin: { left: 2, right: 2, top: 0, bottom: 2 } }
      else
        format.pdf { render template: "patient_cards/print", pdf: "Patient Card", layout: 'pdfgen.html.erb', viewport_size: '1280x1024', page_size: 'A4', disable_smart_shrinking: true, show_as_html: params[:debug].present?, header: { spacing: 0 }, footer: { spacing: 10 } }
      end
    end
  end
end
