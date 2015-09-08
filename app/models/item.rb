# -*- encoding : utf-8 -*-
class Item < ActiveRecord::Base
	has_many :item_categories, dependent: :destroy
  has_many :categories, through: :item_categories
	has_many :item_departments, dependent: :destroy
  has_many :departments, through: :item_departments
  # 未注册的入围供应商
  has_many :unregistered_departments, -> { where(department_id: nil) }, class_name: "ItemDepartment", dependent: :destroy
  # 已注册的入围供应商
  has_many :registered_departments, -> { where.not(department_id: nil) }, class_name: "ItemDepartment", dependent: :destroy

	default_scope -> {order("id desc")}

	before_save do 
		self.category_ids = self.categoryids.split(",")
	end

	after_save do 
		self.item_departments.destroy_all if self.item_departments.present?
		arr = []
		self.dep_names.split("\r\n").each do |name|
			dep = Department.find_by(name: name)
			arr << (dep.present? ? { name: name, department_id: dep.id } : { name: name })
		end
		self.item_departments.create(arr)
	end

	include AboutStatus

	# 中文意思 状态值 标签颜色 进度 
	def self.status_array
		[
	    ["暂存",0,"orange",10],
	    ["有效",1,"blue",50],
      ["停止申请",2,"red",0],
	    ["已删除",404,"light",0]
    ]
  end

  # 根据不同操作 改变状态
  def change_status_hash
    {
      "提交" => { "暂存" => "有效" },
      "停止" => { "有效" => "停止申请" },
      "恢复" => { "停止申请" => "有效" },
      "删除" => { "暂存" => "已删除" },
    }
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end

  def cando(act='')
    case act
    when "update", "edit" then [0].include?(self.status)
    when "commit" then self.can_opt?("提交")
    when "delete", "destroy" then self.can_opt?("删除")
    when "recover", "update_recover" then self.can_opt?("恢复")
    when "pause", "update_pause" then self.can_opt?("停止")
    else false
    end
  end

  # 根据 department_id 判断该单位是否入围本项目
  def finalist?(department_id)
    item_department = self.registered_departments.find_by(department_id: department_id)
    return item_department.present?
  end

  # 保存后提示哪些供应商已经注册 哪些没有注册
  def tips
		unregistered_names = self.unregistered_departments.map(&:name).join(", ")
		registered_names = self.registered_departments.map(&:name).join(", ")
		tips = []
		tips << "[#{unregistered_names}] 还未注册，请联系供应商注册" if unregistered_names.present?
		tips << "[#{registered_names}] 已注册，提交项目后给这些供应商插入待办事项" if registered_names.present?
		return tips
	end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='项目名称' column='name' class='required'/>
        <node name='项目类型' column='item_type' data_type='radio' data='#{Dictionary.item.item_type}'/>
        <node name='品目分配' class='tree_checkbox required' json_url='/kobe/shared/category_ztree_json' partner='categoryids'/>
        <node column='categoryids' data_type='hidden'/>
        <node name='有效期开始时间' column='begin_time' class='date_select required dateISO'/>
        <node name='有效期截止时间' column='end_time' class='date_select required dateISO'/>
        <node name='入围供应商' column='dep_names' data_type='textarea' class='required' hint='请用回车作为分隔符'/>
      </root>
    }
  end

end
