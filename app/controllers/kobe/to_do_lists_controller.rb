# -*- encoding : utf-8 -*-
class Kobe::ToDoListsController < KobeController

  before_action :get_to_do_list, :only => [:delete, :destroy]

  # cancancan验证 如果有before_action cancancan放最后
  load_and_authorize_resource 
  
	def index
		@q = ToDoList.ransack(params[:q]) 
    @to_do_lists = @q.result.status_not_in(404).page params[:page]
	end

  def new
  	to_do_list = ToDoList.new
    @myform = SingleForm.new(ToDoList.xml, to_do_list, { form_id: "to_do_list_form", action: kobe_to_do_lists_path, grid: 2 })
  end

  def edit
    @myform = SingleForm.new(ToDoList.xml, @to_do_list, { form_id: "to_do_list_form", action: kobe_to_do_list_path(@to_do_list), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@to_do_list,ToDoList.xml, grid: 2) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@to_do_list) }
  end

  def create
  	create_and_write_logs(ToDoList, ToDoList.xml)
    redirect_to kobe_to_do_lists_path
  end

  def update
    update_and_write_logs(@to_do_list, ToDoList.xml)
    redirect_to kobe_to_do_lists_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_to_do_list_form', action: kobe_to_do_list_path(@to_do_list), method: 'delete' }
  end

  def destroy
    @to_do_list.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_to_do_lists_path
  end

  private  

    def get_to_do_list
      @to_do_list = ToDoList.find_by(id: params[:id]) if params[:id].present?
      cannot_do_tips unless @to_do_list.present? && @to_do_list.cando(action_name)
    end

end