# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_obj, :only => [:show, :edit, :update, :destroy]

  def index
    @objs = Order.where(get_conditions).page params[:page]
  end

  def new
  	obj = Order.new
  	obj.buyer = obj.payer = current_user.department.name
    slave_objs = [OrdersItem.new(order_id: obj.id)]
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,obj,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, grid: 2},{title: '产品明细', grid: 4})
  end

  def show
    obj_contents = show_obj_info(@obj,Order.xml,{title: "基本信息"})
    @obj.items.each do |item|
      obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{item.id}"})
    end
    @arr  = []
    @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
    @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@obj)}
    @arr << {title: "评价", icon: "fa-star-half-o", content: show_estimates(@obj)}
    @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@obj)}
  end

  def create
    obj = create_msform_and_write_logs(Order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"})
    unless obj.id
      redirect_back_or
    else
      redirect_to kobe_orders_path
    end
  end

  def update
    update_msform_and_write_logs(@obj, Order.xml, OrdersItem, OrdersItem.xml, {:action => "修改订单", :master_title => "基本信息",:slave_title => "产品信息"})
    redirect_to kobe_orders_path
  end

  def edit
    slave_objs = @obj.items.blank? ? [OrdersItem.new(order_id: @obj.id)] : @obj.items
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@obj,slave_objs,{upload_files: true, title: '<i class="fa fa-wrench"></i> 修改订单',action: kobe_order_path(@obj), method: "patch", grid: 2},{title: '产品明细', grid: 4})
  end

  private

    def get_obj
      @obj = Order.find(params[:id]) unless params[:id].blank? 
    end

end
