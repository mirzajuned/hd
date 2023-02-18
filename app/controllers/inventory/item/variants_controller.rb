class Inventory::Item::VariantsController < ApplicationController
  before_action :authorize, :verify_store
  before_action :set_inventory_item_variant, only: [:show, :edit, :update, :disable, :destroy]

  def index
    @store_id = params[:store_id]
    @inventory_store = Inventory::Store.find_by(id: params[:store_id])
    @category = params[:item_type]
    @stock = params[:stock]
    fetch_variant_index
  end

  def append_index
    @store_id = params[:store_id]
    @category = params[:item_type]
    fetch_variant_index
  end

  def filter_index
    @store_id = params[:store_id]
    @category = params[:item_type]
    @stock = params[:stock]
    fetch_variant_index
  end

  def show
    @variant_histories = Inventory::Audit::History.where(variant_id: params[:id]).order_by(created_at: 'desc')
    @lots = Inventory::Item::Lot.where(variant_id: @inventory_item_variant.id, 'stock' => { '$gte' => 1 },
                                       is_deleted: false)
  end

  def new
    @inventory_item_variant = Inventory::Item::Variant.new
  end

  def edit; end

  def create
    @inventory_item_variant = Inventory::Item::Variant.new(inventory_item_variant_params)

    respond_to do |format|
      if @inventory_item_variant.save
        format.html { redirect_to @inventory_item_variant, notice: 'Variant was successfully created.' }
      else
        format.html { render action: 'new' }
      end
    end
  end

  def update
    respond_to do |format|
      if @inventory_item_variant.update(inventory_item_variant_params)
        format.html { redirect_to @inventory_item_variant, notice: 'Variant was successfully updated.' }
      else
        format.html { render action: 'edit' }
      end
    end
  end

  def disable
    reference_id = @inventory_item_variant.reference_id
    inventory_variants = Inventory::Item::Variant.where(reference_id: reference_id)
    inventory_variants_stock = inventory_variants.pluck(:stock).map(&:to_i).inject(&:+)

    if inventory_variants_stock == 0
      inventory_variants.update_all(is_disabled: true)
      @category = ['all_item']
      @store_id = @inventory_item_variant.store_id
      fetch_variant_index
    else
      respond_to do |format|
        format.js { render js: "notice = new PNotify({ title: 'Warning', text: 'Cannot Remove Variant. Stock is still present.', type: 'error' }); notice.get().click(function(){ notice.remove() });" }
      end
    end
  end

  def destroy
    @inventory_item_variant.destroy
    respond_to do |format|
      format.html { redirect_to inventory_item_variants_url }
      format.json { head :no_content }
    end
  end

  def filter_variant
    @store_id = params[:store_id]
    @department_id = params[:department_id]
  end

  def download_data
    stock = params[:stock]
    category = JSON.parse(params[:item_type]&.join(', '))
    store_id = params[:store_id]
    @data_array = Inventory::Variants::DownloadVariantsService.call(store_id, stock, category)
    @filename = "#{params[:department_name]&.downcase}_variant_level_report.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers['Content-Disposition'] = "attachment; filename=\"#{@filename}\"" }
    end
  end

  private

  def fetch_variant_index
    @inventory_store = Inventory::Store.find_by(id: @store_id)
    current_data_row = params[:total_count_row].to_i
    query = params[:q].to_s
    if @inventory_store.present?
      if @category.present?
        if (@category.include? 'all_item') || @category_id.blank? #for store item index
          options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
        else
          options = { store_id: @inventory_store.id, :category_id.in => [@category_id], level: 'store'}
        end
      else
        options = { store_id: @inventory_store.id, :category_id.in => @inventory_store.category_ids, level: 'store' }
      end

    else #for org items index
      options = { organisation_id: current_user.organisation_id, level: 'organisation' }
    end
    if @stock == 'out_stock'
      options = options.merge(empty: true)
    elsif @stock == 'running_low'
      options = options.merge(running_low: true)
    end
    options = options.merge!(search: /#{Regexp.escape(query)}/i) if query.present?
    @variants = Inventory::Item::Variant.where(options).is_active.order_by(created_at: 'desc').skip(current_data_row)
                                        .limit(30)
  end

  def set_inventory_item_variant
    @inventory_item_variant = Inventory::Item::Variant.find_by(id: params[:id])
  end

  def inventory_item_variant_params
    params.require(:inventory_item_variant).permit(:name, :facility_id, :organisation_id, :is_deleted)
  end
end
