# -*- encoding : utf-8 -*-
class Kobe::ContractTemplatesController < KobeController

  before_action :get_ct, :only => [:edit, :update, :delete, :destroy, :show, :index]

  # cancancan验证 如果有before_action cancancan放最后
  load_and_authorize_resource 
  
	def index
		@q = ContractTemplate.ransack(params[:q]) 
    @cts = @q.result.status_not_in(404).page params[:page]
	end

  def new
  	ct = ContractTemplate.new
    @myform = SingleForm.new(ContractTemplate.xml, ct, { form_id: "ct_form", action: kobe_contract_templates_path, grid: 3 })
  end

  def edit
    @myform = SingleForm.new(ContractTemplate.xml, @ct, { form_id: "ct_form", action: kobe_contract_template_path(@ct), method: "patch", grid: 3 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@ct,ContractTemplate.xml, grid: 3) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@ct) }
  end

  def create
  	create_and_write_logs(ContractTemplate, ContractTemplate.xml)
    redirect_to kobe_contract_templates_path
  end

  def update
    update_and_write_logs(@ct, ContractTemplate.xml)
    redirect_to kobe_contract_templates_path
  end

  # 删除
  def delete
    cannot_do_tips unless @ct.can_opt?("删除")
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_ct_form', action: kobe_contract_template_path(@ct), method: 'delete' }
  end

  def destroy
    @ct.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_contract_templates_path
  end

  private  

    def get_ct
      @ct = ContractTemplate.find_by(id: params[:id]) if params[:id].present?
    end

end