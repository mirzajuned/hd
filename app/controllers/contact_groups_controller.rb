class ContactGroupsController < ApplicationController
  def index
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id)
    @contact_group = ContactGroup.new
  end

  def create
    @contact_groups = ContactGroup.where(organisation_id: current_user.organisation_id)
    params[:contact_group][:name] = params[:contact_group][:name].to_s.titleize
    @contact_group = ContactGroup.new(contact_group_params)

    respond_to do |format|
      if @contact_group.save
        format.js { render 'create.js.erb' }
      else
        format.js { render 'error.js.erb' }
      end
    end
  end

  # def save
  #   @deleted_ids = params[:deleted_ids].split(",")
  #   @deleted_ids.try(:each) do |deleted_id|
  #     contactgroup = ContactGroup.find_by(id: deleted_id)
  #     contactgroup.update_attributes(is_deleted: true) if contactgroup.present?
  #   end

  #   params[:contact_group].try(:each) do |contact_group|
  #     @contact_group = ContactGroup.find_by(id: contact_group[:id])
  #     if @contact_group.present?
  #       puts "Name"
  #       puts contact_group[:name]
  #       @contact_group.update_attributes(name: contact_group[:name])
  #     else
  #       @contact_group = ContactGroup.new(name: contact_group[:name], organisation_id: current_user.organisation_id)
  #       if @contact_group.save
  #         puts "Saved"
  #       else
  #         puts "Duplicate"
  #       end
  #     end
  #   end
  # end

  private

  def contact_group_params
    params.require(:contact_group).permit!
  end
end
