# class RoomsController < ApplicationController
#   # before_action :set_ward, only: [:show, :edit, :update, :destroy]
#   before_action :authorize
#   respond_to :js, :json, :html
#   layout "loggedin"

#   # GET /rooms
#   # GET /rooms.json
#   def index
#     @rooms = Room.all
#   end

#   # GET /rooms/1
#   # GET /rooms/1.json
#   def show
#   end

#   def add_r_2_ward
#     # @rooms = (params[:ajax][:rooms]).to_i
#     @counter = (params[:ajax][:counter]).to_i
#     respond_to do |format|
#       format.js { render "rooms/js/add_r_2_ward", layout: false }
#     end
#   end

#   # GET /rooms/new
#   def new
#     # 2.times do
#     #   room = @ward.rooms.build
#     #   3.times do
#     #     room.beds.build
#     #   end
#     # end
#     # question = @survey.questions.build
#     # 4.times { question.answers.build }
#     # 3.times{}
#     # @facility = Facility.new
#     # @facility[:organisation_id] = params[:parent_id]
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   # GET /rooms/1/edit
#   def edit
#     @organisation_id = params[:organisation_id]
#     @ward = Ward.find(params[:id])
#     respond_to do |format|
#       format.js {}
#     end
#   end

#   # POST /rooms
#   # POST /rooms.json
#   def create
#     @ward = Room.new(ward_params)
#     respond_to do |format|
#       if @ward.save
#         format.js { render "show", layout: false }
#         format.html { redirect_to @ward, notice: 'Ward was successfully created.' }
#         format.json { render action: 'show', status: :created, location: @ward }
#       else
#         format.js { render "new", layout: false }
#         format.html { render action: 'new' }
#         format.json { render json: @ward.errors, status: :unprocessable_entity }
#       end
#     end
#   end

#   # ***************************not working******************************
#   def facilities_rooms_list
#     facility_ids = Facility.where(:organisation_id => params[:organisation_id], :is_active => true).map { |p| p.id }
#     @facilities_rooms_list = Ward.where(:facility_id.in => facility_ids)
#     @facilities_rooms_count = @facilities_rooms_list.count
#     @total_facilities_count = @facilities_rooms_list.count
#     @sEcho = params[:sEcho]
#     respond_to do |format|
#       format.json {}
#     end
#   end

#   # ***************************end******************************

#   # PATCH/PUT /rooms/1
#   # PATCH/PUT /rooms/1.json
#   def update
#     respond_to do |format|
#       if @ward.update(ward_params)
#         format.html { redirect_to @ward, notice: 'Ward was successfully updated.' }
#         format.json { head :no_content }
#       else
#         format.html { render action: 'edit' }
#         format.json { render json: @ward.errors, status: :unprocessable_entity }
#       end
#     end
#   end

#   # DELETE /rooms/1
#   # DELETE /rooms/1.json
#   def destroy
#     @organisation_id = params[:organisation_id]
#     @ward.destroy
#     respond_to do |format|
#       format.html { redirect_to rooms_url }
#       format.json { head :no_content }
#     end
#   end

#   private

#   # Use callbacks to share common setup or constraints between actions.
#   def set_ward
#     @ward = Ward.find(params[:id])
#   end

#   # Never trust parameters from the scary internet, only allow the white list through.
#   def ward_params
#     params.require(:ward).permit(:name, :code, :totalbeds, :facility_id, beds_attributes: [:name, :code, :price])
#   end
# end
