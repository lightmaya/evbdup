# -*- encoding : utf-8 -*-

class Department < ActiveRecord::Base
	has_many :user, dependent: :destroy
  has_many :uploads, class_name: :DepartmentsUpload, foreign_key: :master_id
  # validates :name, presence: true, length: { in: 2..30 }, uniqueness: { case_sensitive: false }

  include AboutAncestry
  include AboutStatus

  # 中文意思 状态值 标签颜色 进度 
  def self.status_array
    [
      ["未提交",0,"orange",10],
      ["正常",1,"u",100],
      ["等待审核",2,"blue",50],
      ["冻结",3,"yellow",20],
      ["已删除",404,"red",0]
    ]
  end

  # 附件的类
  def self.upload_model
    DepartmentsUpload
  end

  # 列表中的状态筛选,current_status当前状态不可以点击
  def self.status_filter(action='')
  	# 列表中不允许出现的
  	limited = [404]
  	arr = self.status_array.delete_if{|a|limited.include?(a[1])}.map{|a|[a[0],a[1]]}
  end
  
  # 根据单位的祖先节点判断单位是采购单位还是供应商
  def get_xml
    case self.try(:root_id)
    when 2 then Department.purchaser_xml
    when 3 then Department.supplier_xml
    else Department.other_xml
    end
  end

  # 采购单位XML
  def self.purchaser_xml(who='',options={})

  end

  # 供应商XML
	def self.supplier_xml(who='',options={})
	  %Q{
	    <?xml version='1.0' encoding='UTF-8'?>
	    <root>
	    	<node name='parent_id' data_type='hidden'/>
	      <node name='单位名称' column='name' hint='必须与参照营业执照中的单位名称保持一致' rules='{required:true, maxlength:30, minlength:6, remote: { url:"/kobe/departments/valid_dep_name", type:"post" }}'/>
	      <node name='单位简称' column='short_name'/>
        <node name='曾用名' column='old_name' display='disabled'/>
        <node name='单位类型' column='dep_type' data_type='radio' data='[[0,"独立核算单位"],[1,"部门"]]' hint='独立核算单位是****************'/>
        <node name='营业执照注册号' column='license' hint='请参照营业执照上的注册号' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='税务登记证' column='tax' hint='请参照税务登记证上的号码' rules='{required:true, minlength:15}' messages='请输入15个字符'/>
        <node name='组织机构代码' column='org_code' hint='请参照组织机构代码证上的代码' rules='{required:true, minlength:10}' messages='请输入10个字符'/>
        <node name='单位法人姓名' column='legal_name' class='required'/>
        <node name='单位法人证件类型' class='required' data_type='radio' data='["居民身份证","驾驶证","护照"]'/>
        <node name='单位法人证件号码' column='legal_number' class='required'/>
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

  end

  # can_opt_arr = [:create, :read, :update] 对应cancancan验证的action 
	def cando_list(can_opt_arr=[])
    return "" if can_opt_arr.blank?
		show_div = '#show_ztree_content #ztree_content'
    dialog = "#opt_dialog"
    arr = [] 
    # 查看单位信息
    arr << [self.class.icon_action("详细"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}', '#{show_div}')"] if can_opt_arr.include?(:read)
    # 提交
    arr << [self.class.icon_action("提交"), "/kobe/departments/#{self.id}/commit", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can_opt_arr.include?(:commit) && self.get_tips.blank? and self.status == 0
    # 修改单位信息
    arr << [self.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/edit','#{show_div}')"] if can_opt_arr.include?(:update)
    # 修改资质证书
    arr << [self.class.icon_action("上传资质"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/upload','#{show_div}','edit_upload_fileupload')"] if can_opt_arr.include?(:upload)
    # 维护开户银行
    arr << [self.class.icon_action("维护开户银行"), "javascript:void(0)", onClick: "show_content('/kobe/departments/#{self.id}/show_bank','#{show_div}')"] if can_opt_arr.include?(:bank)
    # 增加下属单位
    arr << [self.class.icon_action("增加下属单位"), "javascript:void(0)", onClick: "show_content('/kobe/departments/new?pid=#{self.id}','#{show_div}')"] if can_opt_arr.include?(:create)
    # 分配人员账号
    title = self.class.icon_action("增加人员")
    arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '/kobe/departments/#{self.id}/add_user', '#{dialog}') }] if can_opt_arr.include?(:add_user)
    return arr
  end

  # 获取提示信息 用于1.注册完成时提交的提示信息、2.登录后验证个人信息是否完整
  def get_tips
    msg = []
    if [0].include?(self.status)
      msg << "单位信息填写不完整，请点击[修改]。" if self.org_code.blank?
      msg << "上传的资质证书不全，请点击[上传资质]。" if self.uploads.length < 4
      msg << "开户银行信息不完整，请点击[维护开户银行]" if self.bank.blank? || self.bank_code.blank?
      msg << "用户信息填写不完整，请在用户列表中点击[修改]。" if self.user.find{ |u| u.name.present? }.blank?
    end
    return msg
  end

  # 维护开户银行提示
  def bank_tips
    msg = []
    msg << "请输入开户银行关键字，例如：开户银行是[招商银行股份有限公司北京西直门支行]，可输入“招商 北京 西直门”"
    msg << "请尽量细化搜索的关键字，搜索结果最多20个"
    msg << "如需修改开户银行，请点击开户银行的银行名称"
  end

  # 是否需要隐藏树形结构 用于没有下级单位的单位 不显示树
  def hide_tree?
    self.is_childless? || self.descendants.where.not(status: 404).blank?
  end

end