# -*- encoding : utf-8 -*-
class Kobe::OrdersController < KobeController

  before_action :get_obj, :only => [:show, :edit, :update, :destroy, :commit]
  skip_before_action :verify_authenticity_token, :only => [:same_template, :commit]

  # cancancan验证 如果有before_action cancancan放最后
  load_and_authorize_resource 
  skip_authorize_resource

  def index
    @q = Order.where(get_conditions("orders")).ransack(params[:q]) 
    @objs = @q.result.page params[:page]
  end

  def new
  	obj = Order.new
  	obj.buyer_name = obj.payer = current_user.department.real_dep.name
    obj.buyer_man = current_user.name
    obj.buyer_tel = current_user.tel
    obj.buyer_mobile = current_user.mobile
    obj.buyer_addr = current_user.department.address
    slave_objs = [OrdersItem.new(order_id: obj.id)]
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,obj,slave_objs,{form_id: 'new_order', upload_files: true, min_number_of_files: 1, title: '<i class="fa fa-pencil-square-o"></i> 下单',action: kobe_orders_path, show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  def show
    obj_contents = show_obj_info(@obj,Order.xml,{title: "基本信息"})
    @obj.items.each_with_index do |item, index|
      obj_contents << show_obj_info(item,OrdersItem.xml,{title: "产品明细 ##{index}"})
    end
    @arr  = []
    @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
    @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@obj)}
    @arr << {title: "评价", icon: "fa-star-half-o", content: show_estimates(@obj)}
    @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@obj)}
  end

  def create
    category_names = params[:orders_items][:category_name].values.join("、")
    project_name = "#{current_user.department.real_dep.name} #{Time.new.to_date.to_s} #{category_names} 定点采购项目"
    other_attrs = { buyer_id: current_user.department.id, buyer_code: current_user.department.real_ancestry, user_id: current_user.id, name: project_name }
    obj = create_msform_and_write_logs(Order, Order.xml, OrdersItem, OrdersItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
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
    @ms_form = MasterSlaveForm.new(Order.xml,OrdersItem.xml,@obj,slave_objs,{form_id: 'new_order', upload_files: true, title: '<i class="fa fa-wrench"></i> 修改订单',action: kobe_order_path(@obj), method: "patch", show_total: true, grid: 4},{title: '产品明细', grid: 4})
  end

  # 提交
  def commit
    # cannot_do_tips unless @obj.can_commit?
    @obj.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false),@obj.commit_params, false)
    @obj.reload.create_task_queue
    tips_get("提交成功。")
    redirect_to kobe_orders_path
  end

  # 根据category_id判断模版是否相同
  def same_template
    templates = Category.where(id: params[:category_ids].split(",")).map(&:ht_template).uniq
    render :text => templates.size
  end

  private

    def get_obj
      @obj = Order.find(params[:id]) unless params[:id].blank? 
    end

end
