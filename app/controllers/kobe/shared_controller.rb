# -*- encoding : utf-8 -*-
class Kobe::SharedController < KobeController
	skip_before_action :verify_authenticity_token
	layout :false
	
  # ajax加载树形结构右侧展示页面的title 用于单位维护、品目参数维护
  def get_ztree_title
  	@obj = eval(params[:model_name]).find_by(id: params[:id])
  end

  # 表单的下拉框 树形结构 只允许menu area category 
  def ztree_json
    if ["Menu", "Area", "Category", "ContractTemplate"].include? params[:json_class]
    	ztree_box_json(params[:json_class].constantize)
    end
  end

  # 转向下一个审核人
  def audit_next_user
    obj = params[:json_class].constantize.find_by(id: params[:id])
    nodes = obj.turn_next_user_json(current_user)
    render :json => nodes.blank? ? "没有相关用户，请先联系管理员授权！" : "[#{nodes.uniq.join(", ")}]"
  end

  private

end
