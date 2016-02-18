# -*- encoding : utf-8 -*-
class Kobe::ItemsController < KobeController

  skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_item, :only => [:edit, :update, :delete, :destroy, :commit, :pause, :update_pause, :update_recover, :recover]

  def index
    @q = Item.where(get_conditions("items")).ransack(params[:q])
    @items = @q.result.page params[:page]
  end

  def new
    @myform = SingleForm.new(Item.xml, @item, { form_id: "item_form", action: kobe_items_path, grid: 3 })
  end

  def edit
    @myform = SingleForm.new(Item.xml, @item, { form_id: "item_form", action: kobe_item_path(@item), method: "patch", grid: 3 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@item,Item.xml, grid: 3) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@item) }
  end

  def create
    item = create_and_write_logs(Item, Item.xml)
    flash_get(item.tips)
    redirect_to kobe_items_path
  end

  def update
    update_and_write_logs(@item, Item.xml, { action: '修改项目' }, { status: 0 })
    flash_get(@item.tips)
    redirect_to kobe_items_path
  end

  # 提交
  def commit
    @item.change_status_and_write_logs("提交", stateless_logs("提交","提交成功！", false))
    # 给已注册的入围供应商加站内消息

    tips_get("提交成功！")
    redirect_to kobe_items_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_item_form', action: kobe_item_path(@item), method: 'delete' }
  end

  def destroy
    @item.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_items_path
  end

  # 停止
  def pause
    render partial: '/shared/dialog/opt_liyou', locals: {form_id: 'pause_item_form', action: update_pause_kobe_item_path(@item)}
  end

  def update_pause
    @item.change_status_and_write_logs("停止",stateless_logs("停止", params[:opt_liyou], false))
    tips_get("停止成功。")
    redirect_to kobe_items_path
  end

  # 恢复
  def recover
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'recover_item_form', action: update_recover_kobe_item_path(@item) }
  end

  def update_recover
    @item.change_status_and_write_logs("恢复", stateless_logs("恢复",params[:opt_liyou],false))
    tips_get("恢复成功。")
    redirect_to kobe_items_path
  end

  # 我的入围项目
  def list
    params[:q][:item_departments_department_id_eq] = current_user.department.id
    @q = Item.where(get_conditions("items")).ransack(params[:q])
    @items = @q.result(distinct: true).includes(:item_departments).page params[:page]
  end

  # 供应商分级
  def classify
    item = Item.find_by(id: params[:item_id])
    cannot_do_tips unless item.present? && item.cando(action_name)
    @q = ItemDepartment.where(item_id: item.id).ransack(params[:q])
    @deps = @q.result.page params[:page]
  end

  def update_classify
    dep = ItemDepartment.where(id: params[:deps].split(",")).update_all(classify: params[:classify].to_i)
    render :text => dep ? "标记成功！" : "标记失败！"
  end

  private

    def get_item
      cannot_do_tips unless @item.present? && @item.cando(action_name)
    end

end
