# -*- encoding : utf-8 -*-
class Category < ActiveRecord::Base
  has_many :products
  validates_with MyValidator

  has_many :user_categories, :dependent => :destroy
  has_many :users, through: :user_categories

  # default_scope -> {order(:ancestry, :sort, :id)}
  default_value_for :status, 65

  scope :usable, -> {where(status: self.effective_status)}

  include AboutStatus
  include AboutAncestry

  after_save do
    if changes["id"].present? || changes["ancestry"].present?
      clean_cache_ids
    end
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    # [["正常", "65", "yellow", 100], ["已删除", "404", "dark", 100], ["已冻结", "12", "dark", 100]]
    self.get_status_array(["正常", "已冻结", "已删除"])
		# [
	 #    ["正常",0,"u",100],
	 #    ["冻结",1,"yellow",0],
	 #    ["已删除",404,"red",100]
  #   ]
  end

  # 根据不同操作 改变状态
  # def change_status_hash
  #   {
  #     "删除" => { 0 => 404 },
  #     "冻结" => { 0 => 1 },
  #     "恢复" => { 1 => 0 }
  #   }
  # end

  # 根据action_name 判断obj有没有操作
  # :index, :delete, :destroy, :freeze, :update_freeze, :recover, :update_recover
  def cando(act='')
    case act
    when "delete", "destroy"
      self.can_opt?("删除")
    when "recover", "update_recover"
      self.can_opt?("恢复")
    when "freeze", "update_freeze"
      self.can_opt?("冻结")
    else false
    end
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='品目名称' column='name' class='required' rules='{ remote: { url:"/kobe/categories/valid_name", type:"post" }}'/>
        <node name='合同模板' column='ht_template' class='required' data_type='select' data='#{Dictionary.ht_template}'/>
        <node name='是否显示在首页' column='show_mall' class='required' data_type='radio' data='#{Dictionary.yes_or_no}'/>
        <node name='业务类型' column='yw_type' class='required' data_type='select' data='#{Dictionary.category_yw_type.values}'/>
        <node name='排序号' column='sort' class='digits' hint='只能输入数字,数字越小排序越靠前'/>
        <node name='审核部门' column='audit_type' class='digits' hint='-1：分公司审核，0：分公司和总公司都审核，1：总公司审核'/>
      </root>
    }
  end

  # 汽车类品目
  def self.qc
    qc = self.find_by(id: 4)
    return qc.present? ? qc.subtree.usable : qc
  end

  # 缓存汽车类品目ID
  def self.cache_qc_ids(force = false)
    if force
      Setting.send("category_qc_ids=", qc.map(&:id))
    else
      Setting.send("category_qc_ids=", qc.map(&:id)) if Setting.send("category_qc_ids").blank?
    end
    Setting.send("category_qc_ids")
  end

  # 建筑工程类品目
  def self.gc
    gc = self.find_by(id: 882)
    return gc.present? ? gc.subtree.usable : gc
  end

  # 缓存建筑工程类品目ID
  def self.cache_gc_ids(force = false)
    if force
      Setting.send("category_gc_ids=", gc.map(&:id))
    else
      Setting.send("category_gc_ids=", gc.map(&:id)) if Setting.send("category_gc_ids").blank?
    end
    Setting.send("category_gc_ids")
  end

  # 包装物类品目
  def self.bzw
    bzw = self.find_by(id: 792)
    return bzw.present? ? bzw.subtree.usable : bzw
  end

  # 缓存包装物类品目ID
  def self.cache_bzw_ids(force = false)
    if force
      Setting.send("category_bzw_ids=", bzw.map(&:id))
    else
      Setting.send("category_bzw_ids=", bzw.map(&:id)) if Setting.send("category_bzw_ids").blank?
    end
    Setting.send("category_bzw_ids")
  end

  # 粮机类品目
  def self.lj
    # lj = self.find_by(id: 2)
    # return lj.present? ? lj.subtree.usable : lj
    not_in_ids = []
    not_in_ids |= self.gc.map(&:id) if self.gc.present?
    not_in_ids |= self.bzw.map(&:id) if self.bzw.present?
    cdt = []
    cdt << "(id = :id or ancestry like :like or ancestry = :id)"
    value = { id: 2, like: "2/%" }
    if not_in_ids.present?
      cdt << "id not in (:not_id)"
      value[:not_id] = not_in_ids
    end
    return self.usable.where([ cdt.join(" and "), value ])

  end

  # 缓存粮机类品目ID
  def self.cache_lj_ids(force = false)
    if force
      Setting.send("category_lj_ids=", lj.map(&:id))
    else
      Setting.send("category_lj_ids=", lj.map(&:id)) if Setting.send("category_lj_ids").blank?
    end
    Setting.send("category_lj_ids")
  end

  # 职工工装类品目
  def self.gz
    gz = self.find_by(id: 56)
    return gz.present? ? gz.subtree.usable : gz
  end

  # 缓存职工工装类品目ID
  def self.cache_gz_ids(force = false)
    if force
      Setting.send("category_gz_ids=", gz.map(&:id))
    else
      Setting.send("category_gz_ids=", gz.map(&:id)) if Setting.send("category_gz_ids").blank?
    end
    Setting.send("category_gz_ids")
  end

  # 办公用品类品目
  def self.bg
    not_in_ids = []
    not_in_ids |= self.qc.map(&:id) if self.qc.present?
    not_in_ids |= self.gz.map(&:id) if self.gz.present?
    cdt = []
    cdt << "(id = :id or ancestry like :like or ancestry = :id)"
    value = { id: 1, like: "1/%" }
    if not_in_ids.present?
      cdt << "id not in (:not_id)"
      value[:not_id] = not_in_ids
    end
    return self.usable.where([ cdt.join(" and "), value ])
  end

  # 缓存办公用品类品目ID
  def self.cache_bg_ids(force = false)
    if force
      Setting.send("category_bg_ids=", bg.map(&:id))
    else
      Setting.send("category_bg_ids=", bg.map(&:id)) if Setting.send("category_bg_ids").blank?
    end
    Setting.send("category_bg_ids")
  end

  # 清除Setting的category_ids
  def clean_cache_ids
    self.class.cache_qc_ids(true)
    self.class.cache_gc_ids(true)
    self.class.cache_bzw_ids(true)
    self.class.cache_lj_ids(true)
    self.class.cache_gz_ids(true)
    self.class.cache_bg_ids(true)
  end

  # 获取关键参数的node is_key="是"
  def get_key_params_nodes
    Nokogiri::XML(self.params_xml).xpath("/root/node[@is_key='是']")
  end

end
