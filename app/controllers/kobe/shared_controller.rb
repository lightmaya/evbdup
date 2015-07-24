# -*- encoding : utf-8 -*-
class Kobe::SharedController < KobeController
	skip_before_action :verify_authenticity_token, :only => [:get_ztree_title, :ztree_json]
	layout :false, :only => :get_ztree_title
	
  # ajax加载树形结构右侧展示页面的title 用于单位维护、品目参数维护
  def get_ztree_title
  	@obj = eval(params[:model_name]).find(params[:id])
  end

  # 表单的下拉框 树形结构 只允许menu area category 
  def ztree_json
    if ["Menu", "Area", "Category"].include? params[:json_class]
    	ztree_box_json(params[:json_class].constantize)
    end
  end

  private

end
