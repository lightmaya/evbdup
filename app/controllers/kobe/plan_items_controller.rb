# -*- encoding : utf-8 -*-
class Kobe::PlanItemsController < KobeController

	skip_before_action :verify_authenticity_token, :only => [:commit]
	before_action :get_item, :only => [:edit, :update, :delete, :destroy, :commit]

	def index
    @q = PlanItem.where(get_conditions("plan_items")).ransack(params[:q]) 
    @plan_items = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(PlanItem.xml, @plan_item, { form_id: "plan_item_form", action: kobe_plan_items_path })
  end

  def edit
    @myform = SingleForm.new(PlanItem.xml, @plan_item, { form_id: "plan_item_form", action: kobe_plan_item_path(@plan_item), method: "patch" })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@plan_item,PlanItem.xml, grid: 1) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@plan_item) }
  end

  def create
  	create_and_write_logs(PlanItem, PlanItem.xml)
    redirect_to kobe_plan_items_path
  end

  def update
    update_and_write_logs(@plan_item, PlanItem.xml)
    redirect_to kobe_plan_items_path
  end

  # 提交
  def commit
    @plan_item.change_status_and_write_logs("提交", stateless_logs("提交","提交成功！", false))
    tips_get("提交成功！")
    redirect_to kobe_plan_items_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_plan_item_form', action: kobe_plan_item_path(@plan_item), method: 'delete' }
  end

  def destroy
    @plan_item.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_plan_items_path
  end

  # 可上报的采购计划
  def list
    params[:q][:status_eq] = 1
    @q = PlanItem.where(get_conditions("plan_items")).ransack(params[:q])
    @plan_items = @q.result.page params[:page]
  end

  private

  	def get_item
      cannot_do_tips unless @plan_item.present? && @plan_item.cando(action_name)
    end

end
