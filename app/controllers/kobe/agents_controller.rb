# -*- encoding : utf-8 -*-
class Kobe::AgentsController < KobeController

  before_action :get_item, :only => [:list, :new, :create]

  skip_authorize_resource :only => [:search_dep_name]

  def index
    params[:q][:user_id_eq] = current_user.id if cannot?(:admin, Agent)
    @q = Agent.where(get_conditions("agents")).ransack(params[:q]) 
    @agents = @q.result.page params[:page]
  end

  def list
    params[:q][:user_id_eq] = current_user.id
    params[:q][:item_id_eq] = @item.id
    @q = Agent.where(get_conditions("agents")).ransack(params[:q]) 
    @agents = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(Agent.xml, @agent, { form_id: "agent_form", action: kobe_agents_path(item_id: @item.id), title: "<i class='fa fa-pencil-square-o'></i> 新增代理商--#{@item.name}", grid: 2 })
  end

  def create
    create_and_write_logs(Agent, Agent.xml, {}, { item_id: @item.id, department_id: current_user.department.id })
    redirect_to list_kobe_agents_path(item_id: @item.id) 
  end

  def update
    update_and_write_logs(@agent, Agent.xml)
    redirect_to list_kobe_agents_path(item_id: @agent.item.id) 
  end

  def edit
    @myform = SingleForm.new(Agent.xml, @agent, { form_id: "agent_form", action: kobe_agent_path(@agent), method: "patch", title: "<i class='fa fa-pencil-square-o'></i> 修改代理商--#{@agent.item.name}", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@agent, Agent.xml, grid: 1) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@agent) }
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_agent_form', action: kobe_agent_path(@agent), method: 'delete' }
  end

  def destroy
    @agent.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  def search_dep_name
    @q = Department.supplier.descendants.limit(20).ransack(params[:q]) 
    @deps = @q.result if params[:q].present?
    render partial: '/kobe/shared/search_dep_name', locals: { search_url: search_dep_name_kobe_agents_path, title: "查找代理商", deps: @deps, input_id: "agents_name" }
  end

  private

    def get_item
      @item = Item.find_by(id: params[:item_id]) if params[:item_id].present?
      cannot_do_tips unless @item.present? && @item.finalist?(current_user.department.id) && @item.item_type
    end

end