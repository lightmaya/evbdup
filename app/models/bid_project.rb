# -*- encoding : utf-8 -*-
class BidProject < ActiveRecord::Base
  has_many :uploads, as: :master
  has_many :items, class_name: "BidItem"
  has_many :bid_item_bids
  has_many :bid_project_bids
  has_one :bid_project_bid
  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "BidProject") }, foreign_key: :obj_id
  belongs_to :user
  has_one :item
  belongs_to :department  

  belongs_to :budget

  default_value_for :status, 0

  scope :can_bid, -> { where("bid_projects.status = #{BidProject.bid_and_choose_status} and now() < bid_projects.end_time") }

  # 模型名称
  Mname = "网上竞价项目"

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end

  after_create do 
    create_no

  end
  
  include AboutStatus
  
  def self.bid_and_choose_status
    16
  end
 
  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
    # [
    #   ["暂存", "0", "orange", 10],
    #   ["需求等待审核", "15", "blue", 30],
    #   ["需求审核拒绝", "14", "red", 20],
    #   ["已发布", "16", "yellow", 40],
    #   ["结果等待审核", "22", "sea", 60],
    #   ["结果审核拒绝", "21", "purple", 50],
    #   ["确定中标人", "23", "yellow", 100],
    #   ["废标等待审核", "29", "sea", 60],
    #   ["废标审核拒绝", "28", "purple", 50],
    #   ["已废标", "33", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "需求等待审核", "需求审核拒绝", "已发布", "结果等待审核", "结果审核拒绝", "确定中标人", "废标等待审核", "废标审核拒绝", "已废标", "已删除"])
		# [
	 #    ["暂存", 0, "orange", 20],
  #     ["需求等待审核", 1, "blue", 40],
  #     ["需求审核拒绝",3,"red", 0],
	 #    ["已发布", 2, "orange", 50],
  #     ["结果等待审核", 4, "sea", 70],
  #     ["结果审核拒绝",5,"red", 50],
  #     ["确定中标人", 12, "u", 100],
  #     ["废标等待审核", 6, "sea", 70],
  #     ["废标审核拒绝",7,"red", 50],
  #     ["已废标", -1, "red", 100],
	 #    ["已删除", 404, "light", 0]
  #   ]
  end
   # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 2 : 1
  #   return {
  #     "提交审核" => { 3 => status_ha, 0 => status_ha },
  #     "删除" => { 0 => 404 },
  #     "通过" => { 1 => 2, 4 => 12, 6 => -1 },
  #     "确定中标人" => {2 => 4},
  #     "废标" => {2 => 6},
  #     "不通过" => { 1 => 3, 4 => 5, 6 => 7 }
  #   # }
  # end


  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u=nil)
    @bid_project = current_u.department.is_zgs? ? BidProject.find_by_id(params[:id]) : current_u.bid_projects.find_by_id(params[:id])
    case act
    when "show"
      true
    when "update", "edit" 
      self.class.edit_status.include?(self.status) && current_u.try(:id) == self.user_id
    when "commit" 
      self.can_opt?("提交") && current_u.try(:id) == self.user_id
    when "update_audit", "audit" 
      self.class.audit_status.include?(self.status)
    when "delete", "destroy" 
      self.can_opt?("删除") && current_u.try(:id) == self.user_id
    when "choose", "pre_choose"
      self.status == BidProject.bid_and_choose_status && self.is_end?
    when "bid"
      self.can_bid?
    else false
    end
  end

  def is_end?
    Time.now - self.end_time > 0
  end
    
  def can_bid?
    self.status == BidProject.bid_and_choose_status && !is_end?
  end

  # 判断是否是指定供应商
  def is_assigned?(user)
    item.blank? || item.departments.include?(user.department)
  end

  def show_logs
    if can_bid?
      doc = Nokogiri::XML(self.logs)
      note = doc.search("/root/node[(@操作内容='报价')]") # find all tags with the node_name "note"
      note.remove
      doc
    else
      Nokogiri::XML(self.logs)
    end
  end

  # 根据品目判断审核人 插入待办事项用
  def audit_user_ids
    self.items.map{|e| e.category.user_ids}.flatten.uniq
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  # def get_tips
  #   msg = []
  #   return msg
  # end

  def self.xml(who = '',options = {})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购单位' column='buyer_dep_name' class='required' display= "readonly" />
        <node name='发票抬头' column='invoice_title' />
        <node name='采购人姓名' column='buyer_name' class='required' />
        <node name='采购人电话' class='buyer_phone' class='required' />
        <node name='采购人手机' column='buyer_mobile' class='required' />
        <node name='采购人地址' column='buyer_add' class='required' />
        <node name='明标或暗标' column='lod' class='required' data='#{Dictionary.lod}' data_type='radio' />
        <node name='投标截止时间' column='end_time' class='required datetime_select datetime' />
        <node name='预算金额（元）' column='budget' class='required number' display="skip" />
        <node name='资质要求' column='req' data_type='textarea' class='required' />
        <node column='item_id' data_type='hidden'/>
        <node name='指定入围供应商' hint='粮机设备必须从入围项目中选择' class='box_radio' json_url='/kobe/shared/item_ztree_json' partner='item_id'/>
        <node name='预算金额（元）' column='budget_money' class='number box_radio' json_url='/kobe/shared/get_budgets_json' partner='budget_id' hint='如果没有可选项，请先填写预算审批单'/>
        <node column='budget_id' data_type='hidden'/>
        <node name='备注信息' column='remark' data_type='textarea' />
      </root>
    }
  end
end
