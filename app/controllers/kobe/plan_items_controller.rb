# -*- encoding : utf-8 -*-
class Kobe::PlanItemsController < KobeController

  # skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_item, :only => [:edit, :update, :result_dep, :update_result_dep] # , :delete, :destroy, :commit
  skip_load_and_authorize_resource only: [:dep_ztree_json]

  def index
    @q = PlanItem.where(get_conditions("plan_items")).ransack(params[:q])
    @plan_items = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(PlanItem.xml, @plan_item, { form_id: "plan_item_form", action: kobe_plan_items_path, grid: 2 })
  end

  def edit
    @myform = SingleForm.new(PlanItem.xml, @plan_item, { form_id: "plan_item_form", action: kobe_plan_item_path(@plan_item), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    con = show_obj_info(@plan_item,PlanItem.xml, grid: 2)
    @plan_item.plan_item_results.each_with_index { |rs, i| con << show_obj_info(rs, PlanItemResult.xml(@plan_item), grid: 2, title: "指定中标供应商 # #{i+1}") }
    @arr << { title: "详细信息", icon: "fa-info", content: con }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@plan_item) }
  end

  def create
    create_and_write_logs(PlanItem, PlanItem.xml)
    redirect_to kobe_plan_items_path
  end

  def update
    update_and_write_logs(@plan_item, PlanItem.xml, { action: '修改项目' })
    redirect_to kobe_plan_items_path
  end

  # 勾选中标供应商
  def dep_ztree_json
    json = []
    deps = params[:ajax_key].present? ? ItemDepartment.where(["item_id = ? and name like ? ", params[:id], "%#{params[:ajax_key]}%"]) : ItemDepartment.where(item_id: params[:id])
    deps.each { |d| json << %Q|{"id":#{d.department_id.present? ? d.department_id : -1}, "pId": #{d.item_id}, "name":"#{d.name}"}| }
    render :json => "[#{json.join(", ")}]"
  end

  # 招标后指定中标供应商
  def result_dep
    @myform = MasterSlaveForm.new(PlanItem.xml('result'), PlanItemResult.xml(@plan_item), @plan_item, @plan_item.plan_item_results,
      {  title: '<i class="fa fa-pencil-square-o"></i> 指定中标供应商',form_id: "plan_item_results_form", action: update_result_dep_kobe_plan_item_path(@plan_item) }, { grid: 2 })
  end

  def update_result_dep
    update_msform_and_write_logs(@plan_item, PlanItem.xml('result'), PlanItemResult, PlanItemResult.xml(@plan_item), { :action => "指定中标供应商" })
    redirect_to kobe_plan_items_path
  end

  # 可上报的采购计划
  # def list
    # @q = PlanItem.where(status: PlanItem.effective_status).ransack(params[:q])
  #   @plan_items = @q.result.page params[:page]
  # end

  private

    def get_item
      cannot_do_tips unless @plan_item.present? && @plan_item.cando(action_name)
    end

end
