# -*- encoding : utf-8 -*-
class Department < ActiveRecord::Base
  has_many :users, dependent: :destroy
  has_many :uploads, class_name: :DepartmentsUpload, foreign_key: :master_id
  # validates :name, presence: true, length: { in: 2..30 }, uniqueness: { case_sensitive: false }

  belongs_to :rule
  has_many :task_queues, -> { where(class_name: "Department") }, foreign_key: :obj_id

  has_many :buyer_orders, class_name: :Order, foreign_key: :buyer_id
  has_many :seller_orders, class_name: :Order, foreign_key: :seller_id

  has_many :item_departments, dependent: :destroy
  has_many :items, through: :item_departments

  scope :find_real_dep,  ->{ where(dep_type: false) }
  scope :valid, -> { where(status: self.effective_status) }

  default_value_for :is_secret, true
  default_value_for :comment_total, 0
  default_value_for :is_blacklist, false


  include AboutAncestry
  include AboutStatus

  default_value_for :status, 0

  before_create do
    # 设置rule_id和rule_step
    init_rule
  end

  after_save do
    real_ancestry_arr = []
    real_ancestry_arr << self.ancestors.where(dep_type: false).map(&:id) if self.ancestors.present?
    real_ancestry_arr << self.id unless self.dep_type

    unless self.real_ancestry == real_ancestry_arr.join("/")
      self.real_ancestry = real_ancestry_arr.join("/") # 祖先和自己中是独立核算单位的id
      self.save
    end

    # 判断是不是入围供应商
    item_deps = ItemDepartment.where(name: self.name, department_id: nil)
    item_deps.update_all(department_id: self.id) if item_deps.present?

  end

  # 有效的入围项目
  def effective_items
    self.items.where(status: Item.effective_status)
  end

  # 拆分real_ancestry 获取独立核算单位的id数组
  def real_ancestry_id_arr
    self.real_ancestry.split("/")
  end

  # 获取单位的第几层祖先 例如总公司(level = 1)还是分公司(level = 2) 单位存在返回该单位 不存在返回nil
  def real_ancestry_level(level)
    dep_id = self.real_ancestry_id_arr[level.to_i]
    return dep_id.present? ? Department.find_by(id: dep_id) : nil
  end

  # 发票单位 real_ancestry最后一位
  def real_dep
    dep_id = self.real_ancestry_id_arr.last
    return Department.find_by(id: dep_id)
  end

  # 独立核算单位下的所有用户
  def real_users
    Department.where(real_ancestry: self.real_ancestry).map(&:users).flatten.uniq
  end

  # 判断单位是不是分公司
  def is_fgs?
    self.root_id == Dictionary.dep_purchaser_id && self.real_ancestry_id_arr.size == 3
  end

  # 判断单位是不是总公司
  def is_zgs?
    self.root_id == Dictionary.dep_purchaser_id && self.real_ancestry_id_arr.size == 2
  end

  # 中文意思 状态值 标签颜色 进度
  def self.status_array
    #  [
    #   ["暂存", "0", "orange", 10],
    #   ["正常", "65", "yellow", 100],
    #   ["等待审核", "8", "blue", 60],
    #   ["审核拒绝", "7", "red", 20],
    #   ["已冻结", "12", "dark", 100],
    #   ["已删除", "404", "dark", 100]
    # ]
    self.get_status_array(["暂存", "正常", "等待审核", "审核拒绝", "已冻结", "已删除"])
    # [
    #   ["未提交",0,"orange",10],
    #   ["正常",1,"u",100],
    #   ["等待审核",2,"blue",50],
    #   ["审核拒绝",3,"red",0],
    #   ["冻结",4,"yellow",20],
    #   ["已删除",404,"light",0]
    # ]
  end

  # 全文检索
  if Rails.env.production?
    searchable do
      text :name, :stored => true, :boost => 10.0
      integer :status
      boolean :is_secret
      text :address
      time :created_at
      time :updated_at
      integer :id
    end
  end

  def self.search(params = {}, options = {})
    options[:page_num] ||= 30
    if options[:all]
      options[:page_num] = Sunspot.search(Product).total
      params[:page] = 1
    end
    options[:is_secret] ||= false
    conditions = Proc.new{
      fulltext params[:k] do
        highlight :name
      end if params[:k].present?
      with(:is_secret, options[:is_secret]) if options[:is_secret].present?
      order_by :id
      paginate :page => params[:page], :per_page => options[:page_num]
    }
    Sunspot.search(Department, &conditions)
  end


  # 根据不同操作 改变状态
  # def change_status_hash
  #   status_ha = self.find_step_by_rule.blank? ? 1 : 2
  #   return {
  #     "提交" => { 3 => status_ha, 0 => status_ha },
  #     "通过" => { 2 => 1 },
  #     "不通过" => { 2 => 3 },
  #     "删除" => { 0 => 404 },
  #     "冻结" => { 1 => 4 },
  #     "恢复" => { 4 => 1 }
  #   }
  # end

  # 附件的类
  def self.upload_model
    DepartmentsUpload
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  # def self.status_filter(action='')
  # 	# 列表中不允许出现的
  # 	limited = [404]
  # 	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  # end

  def self.purchaser
    Department.find_by(id: Dictionary.dep_purchaser_id)
  end

  def self.supplier
    Department.find_by(id: Dictionary.dep_supplier_id)
  end

  # 本单位是不是某单位ID的上级单位
  def is_ancestors?(dep_id)
    dep_id.present? ? self.subtree_ids.include?(dep_id) : false
  end

  # 根据action_name 判断obj有没有操作
  def cando(act='',current_u)
    cdt = current_u.is_admin || current_u.user_type == Dictionary.manage_user_type
    case act
    when "show", "index"
      true
    when "update", "edit", "upload", "update_upload", "show_bank", "edit_bank", "update_bank"
      self.class.edit_status.include?(self.status) && cdt
    when "commit"
      self.get_tips.blank? && self.can_opt?("提交") && cdt
    when "add_user", "update_add_user", "new", "create"
      self.class.effective_status.include?(self.status) && cdt
    when "update_audit", "audit"
      self.class.audit_status.include?(self.status)
    when "delete", "destroy"
      self.can_opt?("删除")
    when "recover", "update_recover"
      self.can_opt?("恢复")
    when "freeze", "update_freeze"
      self.can_opt?("冻结")
    else false
    end
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  def get_tips
    msg = []
    if self.class.only_edit_status.include?(self.status)
      msg << "单位信息填写不完整，请点击[修改]。" if self.area_id.blank?
      msg << "上传附件的不全，请点击[上传附件]。" if self.uploads.length < 2
      msg << "开户银行信息不完整，请点击[维护开户银行]" if self.bank.blank? || self.bank_code.blank?
      msg << "用户信息填写不完整，请在用户列表中点击[修改]。" if self.users.find{ |u| u.name.present? }.blank?
    end
    return msg
  end

  def show_tips_arr
    arr = []
    arr << (self.get_tips.present? || self.status == 7 ? 'error' : 'tips')
    arr << (self.get_tips.present? || self.status == 7 ? '很抱歉！' : '恭喜您！')
    tips = self.status == 7 ? self.get_last_node_by_logs('[操作内容 *= "审核"]')["备注"] : '账户信息已填写完整，请点击[提交]，提交并等待审核。'
    arr << (self.get_tips.present? ? self.get_tips : tips )
  end

  # 维护开户银行提示
  def bank_tips
    Dictionary.tips.bank
  end

  # 是否需要隐藏树形结构 用于没有下级单位的单位 不显示树
  def hide_tree?
    self.is_childless? || self.descendants.status_not_in(404).blank?
  end

  # 根据单位的祖先节点判断单位是采购单位还是供应商
  def get_xml
    case self.try(:root_id)
    when Dictionary.dep_purchaser_id
      Department.purchaser_xml
    when Dictionary.dep_supplier_id
      Department.supplier_xml
    else
      Department.other_xml
    end
  end

  # 采购单位XML
  def self.purchaser_xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='单位名称' column='name' hint='必须与营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:3, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
        <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
        <node name='单位类型' column='dep_type' data_type='radio' data='[[0,"独立核算单位"],[1,"部门"]]' hint='“独立核算单位”是指财务独立，需要单独开具发票的单位。'/>
        <node name='邮政编码' column='post_code' rules='{required:true, number:true}'/>
        <node name='所在地区' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Area"}' partner='area_id'/>
        <node column='area_id' data_type='hidden'/>
        <node name='详细地址' column='address' class='required'/>
        <node name='电话（总机）' column='tel' class='required'/>
        <node name='传真' column='fax' class='required'/>
      </root>
    }
  end

  # 供应商XML
  def self.supplier_xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='单位名称' column='name' hint='必须与营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:6, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
        <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
        <node name='单位类型' column='dep_type' data_type='radio' data='[[0,"独立核算单位"],[1,"部门"]]' hint='独立核算单位是****************'/>
        <node name='营业执照注册号' column='license' hint='请参照营业执照上的注册号' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='税务登记证' column='tax' hint='请参照税务登记证上的号码' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='组织机构代码' column='org_code' hint='请参照组织机构代码证上的代码' rules='{required:true, minlength:10}' messages='请输入10个字符'/>
        <node name='单位法人姓名' column='legal_name' class='required'/>
        <node name='单位法人证件类型' class='required' data_type='radio' data='["居民身份证","驾驶证","护照"]'/>
        <node name='单位法人证件号码' column='legal_number' class='required' rules='{maxlength:18, minlength:18}'/>
        <node name='注册资金' column='capital' class='required'/>
        <node name='年营业额' column='turnover' class='required'/>
        <node name='单位人数' column='employee' data_type='radio' class='required' data='["20人以下","21-100人","101-500人","501-1001人","1001-10000人","1000人以上"]'/>
        <node name='邮政编码' column='post_code' rules='{required:true, number:true}'/>
        <node name='所在地区' class='tree_radio required' json_url='/kobe/shared/ztree_json' json_params='{"json_class":"Area"}' partner='area_id'/>
        <node column='area_id' data_type='hidden'/>
        <node name='详细地址' column='address' class='required'/>
        <node name='公司网址' column='website'/>
        <node name='电话（总机）' column='tel' class='required'/>
        <node name='传真' column='fax' class='required'/>
        <node name='单位介绍' column='summary' data_type='textarea' class='required' placeholder='不超过800字'/>
      </root>
    }
  end

  # 其他单位XML
  def self.other_xml(who='',options={})
    %Q{
      <?xml version='1.0' encoding='UTF-8'?>
      <root>
        <node name='parent_id' data_type='hidden'/>
        <node name='单位名称' column='name' hint='必须与营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:3, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
        <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
      </root>
    }
  end

  # 采购单位进入后台的统计数据
  def get_dep_main

    # 本辖区本年度 采购方式占比
    type_arr = []
    cdt = "year(created_at) = '#{Time.now.year}' and status in (#{Order.ysd_status.join(', ')})"
    total = Order.find_all_by_buyer_code(self.real_ancestry).where(cdt).sum(:total)
    order_count = Order.find_all_by_buyer_code(self.real_ancestry).where(cdt).count
    if total.present?
      type = Order.find_all_by_buyer_code(self.real_ancestry).where(cdt).group('yw_type').select('yw_type, sum(total) as total')
      type_arr = type.map{ |e| [e.yw_type, e.total.to_f, (e.total*100/total).to_f] }
    end

    # 粮机类、汽车、办公类采购统计
    category = Order.find_all_by_buyer_code(self.real_ancestry).where(cdt).group('ht_template').select('ht_template, sum(total) as total')
    category_ha = {}
    category.map{ |e| category_ha[e.ht_template] = e.total.to_f }

    str = show_header("本年度辖区内采购情况", 'fa-line-chart ')
    str << show_category_total("订单数量", "#{order_count} 个")
    str << show_category_total("采购金额", format_total(total))
    str << "<hr>"
    str << show_header("本年度辖区内采购方式占比", 'fa-bar-chart-o')

    Dictionary.yw_type.each_with_index do |a, i|
      next if a[0] == 'grcg'
      yw_type = type_arr.find{|e| e[0] == a[0]}
      str << progress_bar(a[1], (yw_type.present? ? yw_type[2] : 0), Dictionary.colors.map(&:first)[i])
    end

    str << "<hr>"
    str << show_header("粮机物资采购情况", 'fa-vine')

    str << show_category_total("粮机设备", format_total(category_ha['lj']))

    str << show_category_total("建筑工程", format_total(category_ha['gc']))

    str << show_category_total("包装物采购", format_total(category_ha['bzw']))

    lj_per = total == 0 ? 0 : ([category_ha['lj'], category_ha['gc'], category_ha['bzw']].compact.sum * 100)/total
    str << progress_bar("粮机物资采购占比", lj_per, 'purple')

    str << show_header("汽车采购情况", 'fa-car')

    str << show_category_total("汽车采购", format_total(category_ha['qc']))

    qc_per = total == 0 ? 0 : ([category_ha['qc']].compact.sum * 100)/total
    str << progress_bar("汽车采购占比", qc_per, 'brown')

    str << show_header("办公物资采购情况", 'fa-desktop')

    str << show_category_total("办公物资", format_total(category_ha['bg']))

    str << show_category_total("网上商城", format_total(category_ha['ds']))

    str << show_category_total("职工工装", format_total(category_ha['gz']))

    bg_per = total == 0 ? 0 : ([category_ha['bg'], category_ha['ds'], category_ha['gz']].compact.sum * 100)/total
    str << progress_bar("办公物资采购占比", bg_per, 'sea')
  end

  # 供应商销量统计
  def get_seller_main
    # 本年度 销售占比
    type_arr = []
    cdt = "year(created_at) = '#{Time.now.year}' and status in (#{Order.ysd_status.join(', ')})"
    total = Order.find_all_by_seller(self.real_dep.id, self.real_dep.name).where(cdt).sum(:total)
    order_count = Order.find_all_by_seller(self.real_dep.id, self.real_dep.name).where(cdt).count
    if total.present?
      type = Order.find_all_by_seller(self.real_dep.id, self.real_dep.name).where(cdt).group('yw_type').select('yw_type, sum(total) as total')
      type_arr = type.map{ |e| [e.yw_type, e.total.to_f, (e.total*100/total).to_f] }
    end

    str = show_header("本年度销售情况", 'fa-line-chart ')
    str << show_category_total("订单数量", "#{order_count} 个")
    str << show_category_total("销售金额", format_total(total))
    str << "<hr>"
    str << show_header("本年度销售方式占比", 'fa-bar-chart-o')
    Dictionary.yw_type.each_with_index do |a, i|
      next if a[0] == 'grcg'
      yw_type = type_arr.find{|e| e[0] == a[0]}
      str << progress_bar(a[1], (yw_type.present? ? yw_type[2] : 0), Dictionary.colors.map(&:first)[i])
    end
    str
  end

  # 生产单位采购或销量统计的缓存
  def cache_dep_main(force = false)
    if force
      Setting.send("dep_main_#{self.id}=", (self.root_id == Dictionary.dep_purchaser_id ? get_dep_main : get_seller_main))
    else
      Setting.send("dep_main_#{self.id}=", (self.root_id == Dictionary.dep_purchaser_id ? get_dep_main : get_seller_main)) if Setting.send("dep_main_#{self.id}").blank?
    end
    Setting.send("dep_main_#{self.id}")
  end

  # 显示main 统计的标题
  def show_header(title, icon='fa-bar-chart-o')
    %Q{
      <div class="panel-heading-v2 overflow-h">
        <h2 class="heading-xs pull-left"><i class="fa #{icon}"></i> #{title}</h2>
      </div>
    }
  end

  # 后台main 统计采购方式占比
  def progress_bar(title, num, color='u')
    percent = num == 0 ? 0 : format("%0.2f", num)
    %Q{
      <h3 class="heading-xs">#{title} <span class="pull-right">#{percent}%</span></h3>
      <div class="progress progress-u progress-xxs">
        <div style="width: #{percent}%" aria-valuemax="100" aria-valuemin="0" aria-valuenow="#{percent}" role="progressbar" class="progress-bar progress-bar-#{color}">
        </div>
      </div>
    }
  end

  # 后台main 统计粮机、办公、汽车的采购量
  def show_category_total(name, total)
    sum = total.present? ? total : 0
    %Q{
      <div class="row margin-bottom-20">
        <div class="col-xs-6 service-in">#{name}</div>
        <div class="col-xs-6 text-right service-in">#{sum}</div>
      </div>
    }
  end

  # 格式化显示金额 万元
  def format_total(total)
    sum = total.present? ? total : 0
    "¥#{format("%0.2f", sum/10000)} 万元"
  end

end
