# -*- encoding : utf-8 -*-
class Kobe::ContractTemplatesController < KobeController

  before_action :get_ct, :only => [:delete, :destroy]

	def index
		@q = ContractTemplate.ransack(params[:q]) 
    @contract_templates = @q.result.status_not_in(404).page params[:page]
	end

  def new
    @myform = SingleForm.new(ContractTemplate.xml, @contract_template, { form_id: "ct_form", action: kobe_contract_templates_path, grid: 3 })
  end

  def edit
    @myform = SingleForm.new(ContractTemplate.xml, @contract_template, { form_id: "ct_form", action: kobe_contract_template_path(@contract_template), method: "patch", grid: 3 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@contract_template,ContractTemplate.xml, grid: 3) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@contract_template) }
  end

  def create
  	create_and_write_logs(ContractTemplate, ContractTemplate.xml)
    redirect_to kobe_contract_templates_path
  end

  def update
    update_and_write_logs(@contract_template, ContractTemplate.xml)
    redirect_to kobe_contract_templates_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_ct_form', action: kobe_contract_template_path(@contract_template), method: 'delete' }
  end

  def destroy
    @contract_template.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_contract_templates_path
  end

  private  

    def get_ct
      cannot_do_tips unless @contract_template.present? && @contract_template.cando(action_name)
    end

end
