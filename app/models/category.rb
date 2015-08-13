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
	    </root>
	  }
	end

end
