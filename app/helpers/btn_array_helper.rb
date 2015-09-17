# -*- encoding : utf-8 -*-
module BtnArrayHelper

	def users_btn(obj)
    arr = [] 
    dialog = "#opt_dialog"
    # 详细
    if can?(:read, obj) && obj.cando("show")
      title = obj.class.icon_action("详细")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 修改
    if can?(:update, obj) && obj.cando("edit")
      arr << [obj.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('#{edit_kobe_user_path(obj)}','#show_ztree_content #ztree_content')"]
    end
    # 重置密码
    if can?(:reset_password, obj) && obj.cando("reset_password")
      title = obj.class.icon_action("重置密码")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{reset_password_kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 冻结
    if can?(:freeze, obj) && obj.cando("freeze")
      title = obj.class.icon_action("冻结")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{freeze_kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 恢复
    if can?(:recover, obj) && obj.cando("recover")
      title = obj.class.icon_action("恢复")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{recover_kobe_user_path(obj)}', '#{dialog}') }]
    end
    return arr
  end


	def to_do_lists_btn(obj)
    arr = [] 
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_to_do_list_path(obj), target: "_blank"]  if can?(:read, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_to_do_list_path(obj)] if can?(:update, obj)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}", '#{delete_kobe_to_do_list_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete")
    return arr
  end

	def rules_btn(obj)
    arr = [] 
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_rule_path(obj), target: "_blank"]  if can?(:read, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_rule_path(obj)] if can?(:update, obj)
    # 维护审核理由
    arr << [obj.class.icon_action("维护审核理由"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('维护审核理由')}", '#{audit_reason_kobe_rule_path(obj)}', "#opt_dialog") }] if can?(:audit_reason, obj)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}", '#{delete_kobe_rule_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete")
    return arr
  end

	def departments_btn(obj,only_audit=false)
		show_div = '#show_ztree_content #ztree_content'
    dialog = "#opt_dialog"
    arr = [] 
    # 查看单位信息
    arr << [obj.class.icon_action("详细"), "javascript:void(0)", onClick: "show_content('#{kobe_department_path(obj)}', '#{show_div}')"] if can?(:read, obj) && obj.cando("show")
    # 提交
    arr << [obj.class.icon_action("提交"), "#{commit_kobe_department_path(obj)}", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit")
    # 修改单位信息
    arr << [obj.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('#{edit_kobe_department_path(obj)}','#{show_div}')"] if can?(:edit, obj) && obj.cando("edit")
    # 修改资质证书
    arr << [obj.class.icon_action("上传资质"), "javascript:void(0)", onClick: "show_content('#{upload_kobe_department_path(obj)}','#{show_div}','edit_upload_fileupload')"] if can?(:upload, obj) && obj.cando("upload")
    # 维护开户银行
    arr << [obj.class.icon_action("维护开户银行"), "javascript:void(0)", onClick: "show_content('#{show_bank_kobe_department_path(obj)}','#{show_div}')"] if can?(:bank, obj) && obj.cando("show_bank")
    # 增加下属单位
    arr << [obj.class.icon_action("增加下属单位"), "javascript:void(0)", onClick: "show_content('#{new_kobe_department_path(pid: obj.id)}','#{show_div}')"] if can?(:create, obj) && obj.cando("new")
    # 分配人员账号
    title = obj.class.icon_action("增加人员")
    arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{add_user_kobe_department_path(obj)}', '#{dialog}') }] if can?(:add_user, obj) && obj.cando("add_user")
    # 审核
    audit_opt = [obj.class.icon_action("审核"), "#{audit_kobe_department_path(obj)}"] if can?(:audit, obj) && obj.cando("audit")
    if audit_opt.present?
      return [audit_opt] if only_audit
    end
    return arr
  end

	def contract_templates_btn(obj)
    arr = [] 
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_contract_template_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_contract_template_path(obj)] if can?(:update, obj)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_contract_template_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete")
    return arr
  end


	def orders_btn(obj,only_audit=false)
    arr = [] 
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_order_path(obj), target: "_blank"] if can?(:read, obj) && obj.cando("show",current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_order_path(obj)] if can?(:update, obj) && obj.cando("edit",current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_order_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit",current_user)
    # 打印
    arr << [obj.class.icon_action("打印"), print_kobe_order_path(obj), target: "_blank"] if can?(:print, obj) && obj.cando("print",current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_order_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    if audit_opt.present?
      return [audit_opt] if only_audit
    end
   #  # 确认
   #  if [0,1,404].include?(obj.status)
   #  	arr << [obj.class.icon_action("确认订单"), "/kobe/orders/#{obj.id}/confirm"]
   #  end

   #  # 删除
   #  if [0,1,3,4].include?(obj.status)
	  #   arr << [obj.class.icon_action("删除"), "/kobe/orders/#{obj.id}", method: :delete, data: {confirm: "确定要删除吗?"}]
	  # end
   #  # 彻底删除
   #  if obj.status == 404
	  #   arr << [obj.class.icon_action("彻底删除"), "/kobe/orders/#{obj.id}", method: :delete, data: {confirm: "删除后不可恢复，确定要删除吗?"}]
	  # end
	  return arr
	end

  def items_btn(obj)
    arr = [] 
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_item_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_item_path(obj)] if can?(:update, obj) && obj.cando("edit")
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_item_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit")
    # 停止
    arr << [obj.class.icon_action("停止"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('停止')}",'#{pause_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:pause, obj) && obj.cando("pause")
    # 恢复
    arr << [obj.class.icon_action("恢复"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('恢复')}",'#{recover_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:recover, obj) && obj.cando("recover")
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete")
    # 录入产品
    arr << [obj.class.icon_action("录入产品"), item_list_kobe_products_path(item_id: obj.id)] if can?(:item_list, Product) && obj.finalist?(current_user.department.id)
    # 维护代理商
    arr << [obj.class.icon_action("维护代理商"), list_kobe_agents_path(item_id: obj.id)] if can?(:list, Agent) && obj.item_type
    # 维护总协调人
    arr << [obj.class.icon_action("维护总协调人"), list_kobe_products_path(item_id: obj.id)] if can?(:item_list, Product) && obj.item_type
    return arr
  end

  def products_btn(obj,only_audit=false)
    arr = [] 
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_product_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_product_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_product_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 冻结
    arr << [obj.class.icon_action("冻结"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('冻结')}",'#{freeze_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:freeze, obj) && obj.cando("freeze", current_user)
    # 恢复
    arr << [obj.class.icon_action("恢复"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('恢复')}",'#{recover_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:recover, obj) && obj.cando("recover", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_product_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    if audit_opt.present?
      return [audit_opt] if only_audit
    end
    return arr
  end

  def agents_btn(obj)
    arr = [] 
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_agent_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_agent_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_agent_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    return arr
  end

  def articles_btn(obj, only_audit = false)
    arr = [] 
    # 查看详细
    arr << [obj.class.icon_action("详细"), article_path(obj), target: "_blank"]  if can?(:show, obj)
    # 提交
    arr << [obj.class.icon_action("提交审核"), "#{commit_kobe_article_path(obj)}", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit")
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_article_path(obj)] if can?(:update, obj)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_article_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj)
     # 审核
    audit_opt = [obj.class.icon_action("审核"), "#{audit_kobe_article_path(obj)}"] if can?(:audit, obj) && obj.cando("audit")
    if audit_opt.present?
      return [audit_opt] if only_audit
    end
    return arr
  end

  def msgs_btn(obj)
    arr = [] 
    # 查看详细
    arr << [obj.class.icon_action("详细"), "javascript:read_msg(#{obj.id})"]  if can?(:show, obj)
    if obj.status == 0
      # 修改
      arr << [obj.class.icon_action("修改"), edit_kobe_msg_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
      # 发布
      arr << [obj.class.icon_action("发布"), commit_kobe_msg_path(obj), method: "post", data: { confirm: "发布后不允许再修改删除，确定发布吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
      # 删除
      arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_msg_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    end
    return arr
  end

  def msg_users_btn(obj)
    arr = [] 
    # 查看详细
    arr << [obj.msg.class.icon_action("查看"), "javascript:read_msg(#{obj.msg.id})"]  if obj.msg.present? && obj.user_id == current_user.id
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_msg_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    return arr
  end

end
