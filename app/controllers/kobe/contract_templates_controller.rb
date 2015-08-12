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
  	ct = create_and_write_logs(ContractTemplate, ContractTemplate.xml)
    if ct.present?
    	ct.create_file
    end
    redirect_to kobe_contract_templates_path
  end

  def update
    if update_and_write_logs(@ct, ContractTemplate.xml)
			@ct.create_file
    end
    redirect_to kobe_contract_templates_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_ct_form', action: kobe_contract_template_path(@ct), method: 'delete' }
  end

  def destroy
    if @ct.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou],false))
      tips_get("删除成功。")
    else
      flash_get(@ct.errors.full_messages)
    end
    redirect_to kobe_contract_templates_path
  end

  private  

    def get_ct
      @ct = ContractTemplate.find_by(id: params[:id]) if params[:id].present?
    end

end