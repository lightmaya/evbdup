# -*- encoding : utf-8 -*-
class Kobe::CoordinatorsController < KobeController

  before_action :get_item, :only => [:list, :new, :create]
  before_action :get_coordinator, :except => [:index, :list, :new, :create]

  def index
    params[:q][:user_id_eq] = current_user.id if cannot?(:admin, Coordinator)
    @q = Coordinator.where(get_conditions("coordinators")).ransack(params[:q])
    @coordinators = @q.result.page params[:page]
  end

  def list
    params[:q][:user_id_eq] = current_user.id
    params[:q][:item_id_eq] = @item.id
    @q = Coordinator.where(get_conditions("coordinators")).ransack(params[:q])
    @coordinators = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(Coordinator.xml, @coordinator, { form_id: "coordinator_form", action: kobe_coordinators_path(item_id: @item.id), title: "<i class='fa fa-pencil-square-o'></i> 新增总协调人--#{@item.name}", grid: 3 })
  end

  def create
    create_and_write_logs(Coordinator, Coordinator.xml, {}, { item_id: @item.id, department_id: current_user.department.id })
    redirect_to list_kobe_coordinators_path(item_id: @item.id)
  end

  def update
    update_and_write_logs(@coordinator, Coordinator.xml)
    redirect_to list_kobe_coordinators_path(item_id: @coordinator.item.id)
  end

  def edit
    @myform = SingleForm.new(Coordinator.xml, @coordinator, { form_id: "coordinator_form", action: kobe_coordinator_path(@coordinator), method: "patch", title: "<i class='fa fa-pencil-square-o'></i> 修改总协调人--#{@coordinator.item.name}", grid: 3 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@coordinator, Coordinator.xml, grid: 3) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@coordinator) }
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_coordinator_form', action: kobe_coordinator_path(@coordinator), method: 'delete' }
  end

  def destroy
    @coordinator.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  private

    def get_item
      @item = Item.find_by(id: params[:item_id]) if params[:item_id].present?
      cannot_do_tips unless @item.present? && @item.cando("add_coordinator", current_user)
    end

    def get_coordinator
      cannot_do_tips unless @coordinator.present? && @coordinator.cando(action_name,current_user)
    end

end
