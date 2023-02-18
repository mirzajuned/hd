class MedicationsController < ApplicationController
  def set
    @medication_sets = Medicationset.all
  end

  def medication
    @medications = Medication.where(:medicationset_id => medication_params[:medicationsetid])
    render :json => @medications
  end

  private

  def medication_params
    params.require(:medication).permit(:medicationsetname, :medicationsetid)
  end
end
