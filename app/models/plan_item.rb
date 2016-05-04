# -*- encoding : utf-8 -*-
class PlanItem < ActiveRecord::Base

  has_many :plan_item_results, dependent: :destroy
  has_many :categories, through: :plan_item_results
  has_many :plan_item_categories

  before_save do
    self.category_ids = self.categoryids.split(",")
  end

  include AboutStatus

  default_value_for :status, 0

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    self.get_status_array(["暂存", "可报需求", "可报结果", "已完成"])
  end

  # 可上报需求的状态
  def self.xq_status
    [114]
  end

  # 可上报结果的状态
  def self.jg_status
    [121]
  end

  def cando(act='',current_u=nil)
    case act
    when "update", "edit", "result_dep", "update_result_dep"
      true
    # when "commit"
    #   self.can_opt?("提交")
    # when "delete", "destroy"
    #   self.can_opt?("删除")
    when "add_plan"
      self.class.xq_status.include?(self.status) # && self.end_time > Time.now
    else false
    end
  end

  def self.xml(act='',options={})
    status_arr = []
    self.status_array.each{ |e| status_arr << [ e[1], e[0] ] }
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='计划名称' column='name' class='required' #{"display='disabled'" if act == 'result'}/>
        <node name='上报截止时间' column='end_time' class='datetime_select required datetime' #{"display='disabled'" if act == 'result'}/>
        <node name='品目' class='tree_checkbox required' json_url='/kobe/shared/category_ztree_json' partner='categoryids' #{"display='disabled'" if act == 'result'}/>
        <node column='categoryids' data_type='hidden'/>
        <node name='状态' column='status' class='required' data_type='select' data='#{status_arr}' />
        <node column='item_id' data_type='hidden'/>
        <node name='指定入围项目' class='box_radio required' json_url='/kobe/shared/item_ztree_json' partner='item_id' #{"display='disabled'" if act == 'result'}/>
      </root>
    }
  end

end
