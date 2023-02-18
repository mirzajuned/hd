class HolidayPlansController < ApplicationController
  before_action :all_holiday_plans, only: [:index, :update, :destroy]
  def index
    @holiday_plan = HolidayPlan.new
    @button_name = "+ Plan"
    respond_to do |format|
      format.js {}
    end
  end

  def new
    @holiday_plan = HolidayPlan.new
    respond_to do |format|
      format.js { render 'form' }
    end
  end

  def create

    params[:holiday_plan][:start_time] = params[:holiday_plan][:start_date].gsub('/','-') + ' ' +  params[:holiday_plan][:start_time]
    params[:holiday_plan][:end_time] = params[:holiday_plan][:end_date].gsub('/','-') + ' ' +  params[:holiday_plan][:end_time]
    @holiday_plan = HolidayPlan.new(holiday_plan_params)
    if check_validation 
      respond_to { |format| format.js { render 'errors'} }
    else
      if @holiday_plan.save!
        all_holiday_plans
        @holiday_plan = HolidayPlan.new
        @button_name = "+ Plan"
        respond_to do |format|
          format.js { render 'index' }
        end
      else
        respond_to do |format|
          format.js {}
        end
      end
    end
  end

  def edit
    @holiday_plan = HolidayPlan.find(params[:id])
    @button_name = "Update"
    respond_to do |format|
      format.js { render 'edit' }
    end
  end

  def update
    @holiday_plan = HolidayPlan.find(params[:id])

    if check_validation 
      respond_to { |format| format.js { render 'errors'} }
    else

      params[:holiday_plan][:start_time] = params[:holiday_plan][:start_date].gsub('/','-') + ' ' +  params[:holiday_plan][:start_time]
      params[:holiday_plan][:end_time] = params[:holiday_plan][:end_date].gsub('/','-') + ' ' +  params[:holiday_plan][:end_time]
      if @holiday_plan.update_attributes(holiday_plan_params)
        all_holiday_plans
        @holiday_plan = HolidayPlan.new
        @button_name = "+ Plan"        
        respond_to do |format|
          format.js { render 'index' }
        end
      else
        respond_to do |format|
          format.js {}
        end
      end
    end
  end

  def destroy
    @holiday_plan = HolidayPlan.find(params[:id])

    if @holiday_plan.destroy
      all_holiday_plans
      @holiday_plan = HolidayPlan.new
      @button_name = "+ Plan"  
      respond_to do |format|
        format.js { render 'index' }
      end
    else
      respond_to do |format|
        format.js {}
      end
    end
  end

  private

  def holiday_plan_params
    params.require(:holiday_plan).permit(:start_date, :end_date, :start_time, :end_time, :plan, :user_id, :facility_id, :organisation_id, :reason)
  end

  def all_holiday_plans
    # Holiday Plan
    @holiday_plans = HolidayPlan.where(user_id: current_user.id, start_date: DateTime.now..(DateTime.now+100).in_time_zone.utc )

    b = []
    b = @holiday_plans.filter { |data| 
      data.end_date.day == DateTime.now.day && Time.parse( data.start_time.strftime('%H:%M')) < Time.parse(Time.now.strftime('%H:%M')).utc 
    }
    @holiday_plans = @holiday_plans - b
    @holiday_plans.count > 0 ? @holiday_plans_past = HolidayPlan.where(user_id: current_user.id) - @holiday_plans : @holiday_plans_past = HolidayPlan.where(user_id: current_user.id)
    @holiday_plans.sort! { |a,b| 
      a_start = a.start_date.to_s + ' ' + a.start_time.strftime("%I:%M %p").to_s
      b_start = b.start_date.to_s + ' ' + b.start_time.strftime("%I:%M %p").to_s

      DateTime.parse(a_start).utc <=>  DateTime.parse(b_start).utc
    }
    @holiday_plans_past.sort! { |a,b| 
     a_start = a.start_date.to_s + ' ' + a.start_time.strftime("%I:%M %p").to_s
     b_start = b.start_date.to_s + ' ' + b.start_time.strftime("%I:%M %p").to_s

       DateTime.parse(b_start).utc <=> DateTime.parse(a_start).utc 
    }
  end

  def check_validation
    if DateTime.parse(DateTime.now.strftime("%d-%m-%Y"+ ' ' + "%H:%M")) > DateTime.parse(params['holiday_plan']['start_date']+'T'+params['holiday_plan']['start_time']) then return true end # check that past dateTime is not being sent
    if DateTime.parse(params['holiday_plan']['start_date']+'T'+params['holiday_plan']['start_time']).utc == DateTime.parse(params['holiday_plan']['end_date']+'T'+params['holiday_plan']['end_time']).utc then return true end #check if start and end date re same
    if DateTime.parse(params['holiday_plan']['start_date']+'T'+params['holiday_plan']['start_time']).utc > DateTime.parse(params['holiday_plan']['end_date']+'T'+params['holiday_plan']['end_time']).utc then return true end #check if start date is greater than end date
    if DateTime.parse(params['holiday_plan']['end_date']+'T'+params['holiday_plan']['end_time']).utc < DateTime.now.utc then return true end #check enddate and end time is greater than current date and time

    @user_holiday_plan = HolidayPlan.where(user_id: current_user, :id.ne => @holiday_plan.id, start_date: DateTime.now..(DateTime.now+100).in_time_zone.utc)
    if params[:action] == 'update'
      test_start = params['holiday_plan']['start_date'].to_s + ' ' + params['holiday_plan']['start_time']
      test_ending = params['holiday_plan']['end_date'].to_s + ' ' + params['holiday_plan']['end_time']
      test_start = DateTime.parse(test_start).utc
      test_ending = DateTime.parse(test_ending).utc    
    else
      test_start = @holiday_plan.start_date.to_s + ' ' + @holiday_plan.start_time.strftime("%I:%M %P").to_s
      test_ending = @holiday_plan.end_date.to_s + ' ' + @holiday_plan.end_time.strftime("%I:%M %P").to_s
      test_start = DateTime.parse(test_start).utc
      test_ending = DateTime.parse(test_ending).utc
    end
    @user_holiday_plan.all.each do |record|
      start = record.start_date.to_s + ' ' + record.start_time.strftime("%I:%M %p").to_s
      ending = record.end_date.to_s + ' ' + record.end_time.strftime("%I:%M %p").to_s
      start = DateTime.parse(start).utc
      ending = DateTime.parse(ending).utc

      if test_start.between?(start, ending) || test_ending.between?(start,ending) 
        return true 
      end
      if start.between?(test_start, test_ending) || ending.between?(test_start, test_ending) 
        return true 
      end
    end
    false
  end
end
