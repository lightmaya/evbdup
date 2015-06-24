# -*- encoding : utf-8 -*-
class SharedController < JamesController
	skip_before_action :verify_authenticity_token, :only => :get_ztree_title
	layout :false, :only => :get_ztree_title
	
  # 下拉框选择时查询行业分类
  def department
    ztree_json(Department)
  end

  # 下拉框选择时查询地区
  def area
    ztree_json(Area)
  end

  # ajax加载树形结构右侧展示页面的title 用于单位维护、品目参数维护
  def get_ztree_title
  	@obj = eval(params[:model_name]).find(params[:id])
  end

  private

end
