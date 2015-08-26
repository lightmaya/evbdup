# -*- encoding : utf-8 -*-
class Category < ActiveRecord::Base
	has_many :products
  validates_with MyValidator

  has_many :user_categories, :dependent => :destroy
  has_many :users, through: :user_categories

  default_scope -> {order(:ancestry, :sort, :id)}

  include AboutStatus
  include AboutAncestry

  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["正常",0,"u",100],
	    ["冻结",1,"yellow",0],
	    ["已删除",404,"red",100]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "删除" => { "正常" => "已删除" },
      "冻结" => { "正常" => "冻结" },
      "恢复" => { "冻结" => "正常" }
    }
  end

  # 根据action_name 判断obj有没有操作
  # :index, :delete, :destroy, :freeze, :update_freeze, :recover, :update_recover
  def cando(act='')
    case act
    when "delete", "destroy" then self.can_opt?("删除")
    when "recover", "update_recover" then self.can_opt?("恢复")
    when "freeze", "update_freeze" then self.can_opt?("冻结")
    else false
    end
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def self.xml(who='',options={})
  	ht_data = ContractTemplate.status_not_in(404).map{ |e| [e.file_name, e.name] }
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	    	<node name='品目名称' column='name' class='required' rules='{ remote: { url:"/kobe/categories/valid_name", type:"post" }}'/>
	    	<node name='合同模板' column='ht_template' class='required' data_type='select' data='#{ht_data}'/>
	    	<node name='是否显示在首页' column='show_mall' class='required' data_type='radio' data='[[1,"是"],[0,"否"]]'/>
	      <node name='是否采购计划显示' column='show_plan' class='required' data_type='radio' data='[[1,"是"],[0,"否"]]'/>
	      <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
        <node name='审核部门' column='audit_type' class='digits' hint='-1：分公司审核，0：分公司和总公司都审核，1：总公司审核'/>
	    </root>
	  }
	end

  # 汽车类品目
  def self.qc
    qc = self.find_by(id: 4)
    return qc.present? ? qc.subtree.where(status: 0) : qc
  end

  # 粮机类品目
  def self.lj
    lj = self.find_by(id: 2)
    return lj.present? ? lj.subtree.where(status: 0) : lj
  end

  # 职工工装类品目
  def self.gz
    gz = self.find_by(id: 56)
    return gz.present? ? gz.subtree.where(status: 0) : gz
  end

  # 办公用品类品目
  def self.bg
    not_in_ids = []
    not_in_ids |= self.qc.map(&:id) if self.qc.present?
    not_in_ids |= self.gz.map(&:id) if self.gz.present?
    cdt = []
    cdt << "status = :status"
    cdt << "(id = :id or ancestry like :like or ancestry = :id)"
    value = { status: 0, id: 1, like: "1/%" }
    if not_in_ids.present?
      cdt << "id not in (:not_id)"
      value[:not_id] = not_in_ids
    end
    return self.where([ cdt.join(" and "), value ])
  end

end
