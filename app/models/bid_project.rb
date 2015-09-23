# -*- encoding : utf-8 -*-
class BidProject < ActiveRecord::Base
  has_many :uploads
  has_many :items, class_name: "BidItem"
  
  include AboutStatus
   # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	# limited = [404]
    limited = []
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end
  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存", 0, "orange", 50],
      ["等待审核", 1, "orange", 90],
	    ["已发布", 2, "u", 100],
      ["审核拒绝",3,"red",0],
	    ["已删除", 404, "red", 0]
    ]
  end
   # 根据不同操作 改变状态
  def change_status_hash
    {
      "提交审核" => { 0 => 1 },
      "删除" => { 0 => 404 },
      "通过" => { 1 => 2 },
      "不通过" => { 1 => 3 }
    }
  end


  # 根据action_name 判断obj有没有操作
  def cando(act='')
    case act
    when "commit" 
      [0].include?(self.status) && self.get_tips.blank?
    when "update_audit", "audit" 
      self.can_opt?("通过") && self.can_opt?("不通过")
    else false
    end
  end

    # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  def get_tips
    msg = []
    return msg
  end

  def commit_params
    arr = []
    # rule_id = Rule.find_by(yw_type: self.class.to_s).try(:id)
    arr << "rule_id = 3"
    arr << "rule_step = 'start'"
    return arr
  end

  def self.xml(who = '',options = {})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='采购类别' column='buy_type' class='required' data='#{Dictionary.buy_type}'  data_type='select'/>
        <node name='上级单位' column='top_dep_name' class='required' display= "readonly" />
        <node name='采购单位' column='buyer_dep_name' class='required' display= "readonly" />
        <node name='发票单位' column='invoice_title' />
        <node name='采购人姓名' column='buyer_name' class='required' />
        <node name='采购人电话' class='buyer_phone' class='required' />
        <node name='采购人手机' column='buyer_mobile' class='required' />
        <node name='采购人电子邮箱' column='buyer_email' class='required' />
        <node name='采购人地址' column='buyer_add' class='required' />
        <node name='明标或暗标' column='lod' class='required' data='#{Dictionary.lod}'  data_type='select' />
        <node name='投标截止时间' column='end_time' class='required my97_time' />
        <node name='预算金额（元）' column='budget' class='required number' />
        <node name='资质要求' column='req' data_type='textarea' class='required' />
        <node name='备注信息' column='remark' data_type='textarea' />
      </root>
    }
  end
end