# -*- encoding : utf-8 -*-
class Product < ActiveRecord::Base
	has_many :uploads, class_name: :ProductsUpload, foreign_key: :master_id
	default_scope -> {order("id desc")}
	belongs_to :category


  # validates_with MyValidator

	include AboutStatus

	# 附件的类
  def self.upload_model
    ProductsUpload
  end

  # 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["未提交",0,"orange",10],
	    ["等待审核",1,"blue",50],
	    ["正常",2,"u",100],
      ["冻结",3,"yellow",0],
	    ["已删除",404,"red",0]
    ]
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def cando_list(action='')
    arr = [] 
    # 查看详细
    if [0,1,2,3,404].include?(self.status)
    	arr << [self.class.icon_action("详细"), "/kobe/products/#{self.id}", target: "_blank"]
   	end
    # 修改
    if [0,3,404].include?(self.status)
    	arr << [self.class.icon_action("修改"), "/kobe/products/#{self.id}/edit"]
    end
	  return arr
  end

  def self.more_actions_list(action='')
    arr = []
    arr << [self.icon_action("增加"), "javascript:void(0)", json_url: "/json/categories", class: 'tree_checkbox']
    arr << [self.icon_action("冻结"), "/kobe/products/freeze"]
    arr << [self.icon_action("恢复"), "/kobe/products/recover"]
    arr << [self.icon_action("删除"), "/kobe/products/delete"]
    arr << [self.icon_action("彻底删除"), "/kobe/products/clean"]
  end

end
