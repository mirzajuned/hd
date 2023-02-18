class TaskListsController < ApplicationController
  before_action :authorize
  before_action :tasks
  before_action :task, only: [:change_status, :destroy, :update, :edit]

  def create
    @newtask = TaskList.new(task_list_params)
    @newtask.organisation_id = current_user.organisation_id.to_s
    @newtask.user_id = current_user.id.to_s
    if @newtask.save
      respond_to do |format|
        format.js { render 'refresh_task.js.erb', layout: false }
      end
    end
  end

  def edit
  end

  def update
    @task.update(comment: params[:comment])
    respond_to do |format|
      format.js { render 'refresh_task.js.erb', layout: false }
    end
  end

  def change_status # Completed or Not
    if @task.update(is_complete: params[:is_complete])
      # respond_to do |format|
      #   format.js { render 'refresh_task.js.erb', layout: false}
      # end
    end
    head :ok
  end

  def destroy
    @task.update(is_active: false)
    respond_to do |format|
      format.js { render 'refresh_task.js.erb', layout: false }
    end
  end

  def save_list_order
    task_ordered_ids = params[:order]
    task_ordered_ids.each_with_index do |id, i|
      @task = TaskList.find(id)
      @task.update(position: i + 1)
    end
    head :ok
  end

  private

  def task_list_params
    params.permit(:comment, :creation_date, :completion_date, :user_id, :organisation_id, :is_complete, :position, :is_active)
  end

  def tasks
    @tasks = TaskList.where(organisation_id: current_user.organisation_id).order(:position => :asc)
  end

  def task
    @task = TaskList.find(params[:id])
  end
end
