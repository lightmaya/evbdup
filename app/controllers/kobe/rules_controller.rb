# -*- encoding : utf-8 -*-
class Kobe::RulesController < KobeController

  before_action :get_rule, :only => [:delete, :destroy]

	def index
		@q = Rule.ransack(params[:q]) 
    @rules = @q.result.status_not_in(404).page params[:page]
	end

  def new
  	rule = Rule.new
    slave_objs = rule.create_rule_objs
    @ms_form = MasterSlaveForm.new(Rule.xml, RuleStep.xml, rule, slave_objs, { form_id: 'rule_form', action: kobe_rules_path, grid: 3 }, { title: 'Step', grid: 4 })
  end

  def edit
    slave_objs = @rule.create_rule_objs
    @ms_form = MasterSlaveForm.new(Rule.xml, RuleStep.xml, @rule, slave_objs, { form_id: 'rule_form', action: kobe_rule_path(@rule), method: "patch", grid: 3 }, { title: 'Step', grid: 4 })
  end

  def show
    @arr  = []
    obj_contents = show_obj_info(@rule,Rule.xml,{grid: 3})
    @rule.create_rule_objs.each_with_index do |step,index|
      obj_contents << show_obj_info(step,RuleStep.xml,{title: "Step ##{index+1}"})
    end
    @arr << {title: "详细信息", icon: "fa-info", content: obj_contents} 
    @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@rule)}
  end

  def create
    rule = create_and_write_logs(Rule, Rule.xml, { :action => "新增" }, { "rule" => RuleStep.create_rule_xml(params) })
    redirect_to kobe_rules_path
  end

  def update
    update_and_write_logs(@rule, Rule.xml, { :action => "修改" },  { "rule" => RuleStep.create_rule_xml(params) })
    redirect_to kobe_rules_path
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_rule_form', action: kobe_rule_path(@rule), method: 'delete' }
  end

  def destroy
    @rule.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_rules_path
  end

  # 维护审核理由
  def audit_reason
    render partial: '/kobe/shared/show_xml_column', locals: { obj: @rule, column: "audit_reason" }
  end

  private  

    def get_rule
      cannot_do_tips unless @rule.present? && @rule.cando(action_name)
    end

end
