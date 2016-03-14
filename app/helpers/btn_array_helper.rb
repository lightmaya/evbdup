# -*- encoding : utf-8 -*-
module BtnArrayHelper

  def users_btn(obj)
    arr = []
    dialog = "#opt_dialog"
    # 详细
    if can?(:read, obj) && obj.cando("show", current_user)
      title = obj.class.icon_action("详细")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 修改
    if can?(:update, obj) && obj.cando("edit", current_user)
      arr << [obj.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('#{edit_kobe_user_path(obj)}','#show_ztree_content #ztree_content')"]
    end
    # 重置密码
    if can?(:reset_password, obj) && obj.cando("reset_password", current_user)
      title = obj.class.icon_action("重置密码")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{reset_password_kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 冻结
    if can?(:freeze, obj) && obj.cando("freeze", current_user)
      title = obj.class.icon_action("冻结")
      arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{freeze_kobe_user_path(obj)}', '#{dialog}') }]
    end
    # 恢复
    if can?(:recover, obj) && obj.cando("recover", current_user)
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
    arr << [obj.class.icon_action("详细"), "javascript:void(0)", onClick: "show_content('#{kobe_department_path(obj)}', '#{show_div}')"] if can?(:read, obj) && obj.cando("show", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), "#{commit_kobe_department_path(obj)}", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 修改单位信息
    arr << [obj.class.icon_action("修改"), "javascript:void(0)", onClick: "show_content('#{edit_kobe_department_path(obj)}','#{show_div}')"] if can?(:edit, obj) && obj.cando("edit", current_user)
    # 修改资质证书
    arr << [obj.class.icon_action("上传附件"), "javascript:void(0)", onClick: "show_content('#{upload_kobe_department_path(obj)}','#{show_div}','edit_upload_fileupload')"] if can?(:upload, obj) && obj.cando("upload", current_user)
    # 维护开户银行
    arr << [obj.class.icon_action("维护开户银行"), "javascript:void(0)", onClick: "show_content('#{show_bank_kobe_department_path(obj)}','#{show_div}')"] if can?(:bank, obj) && obj.cando("show_bank", current_user)
    # 增加下属单位
    arr << [obj.class.icon_action("增加下属单位"), "javascript:void(0)", onClick: "show_content('#{new_kobe_department_path(pid: obj.id)}','#{show_div}')"] if can?(:create, obj) && obj.cando("new", current_user)
    # 分配人员账号
    title = obj.class.icon_action("增加人员")
    arr << [title, dialog, "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{title}", '#{add_user_kobe_department_path(obj)}', '#{dialog}') }] if can?(:add_user, obj) && obj.cando("add_user", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), "#{audit_kobe_department_path(obj)}"] if can?(:audit, obj) && obj.cando("audit", current_user)
    return [audit_opt] if audit_opt.present? && only_audit
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
    name= obj.invoice_number.present? ? "已开发票" : "未开发票"
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_order_path(obj), target: "_blank"] if can?(:read, obj) && obj.cando("show",current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_order_path(obj)] if can?(:update, obj) && obj.cando("edit",current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_order_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit",current_user)
    # 打印
    arr << [obj.class.icon_action("打印"), "#opt_dialog", "data-toggle" => "modal",onClick: %Q{ modal_dialog_show("#{obj.class.icon_action("打印 合同/凭证")}", "#{print_kobe_order_path(obj)}", '#opt_dialog') } ] if can?(:print_order, obj) && obj.cando("print",current_user)
    #是否开发票
    arr << [obj.class.icon_action(name), "#opt_dialog" , "data-toggle" => "modal" , onClick: %Q{ modal_dialog_show("#{obj.class.icon_action("发票编号")}" , "#{invoice_number_kobe_order_path(obj)}",'#opt_dialog')} ] if can?(:invoice_number, obj) && obj.cando("invoice_number",current_user)
    # 卖方确认
    arr << [obj.class.icon_action("卖方确认"), agent_confirm_kobe_order_path(obj)] if can?(:agent_confirm, obj) && obj.cando("agent_confirm",current_user)
    # 买方确认
    arr << [obj.class.icon_action("买方确认"), buyer_confirm_kobe_order_path(obj)] if can?(:buyer_confirm, obj) && obj.cando("buyer_confirm",current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_order_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def items_btn(obj)
    arr = []
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_item_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_item_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_item_path(obj), method: "post", data: { confirm: "确认无误后，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 停止
    arr << [obj.class.icon_action("停止"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('停止')}",'#{pause_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:pause, obj) && obj.cando("pause", current_user)
    # 恢复
    arr << [obj.class.icon_action("恢复"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('恢复')}",'#{recover_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:recover, obj) && obj.cando("recover", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_item_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 录入产品
    arr << [obj.class.icon_action("录入产品"), item_list_kobe_products_path(item_id: obj.id)] if can?(:item_list, Product) && obj.cando("add_product", current_user)
    # 维护代理商
    arr << [obj.class.icon_action("维护代理商"), list_kobe_agents_path(item_id: obj.id)] if can?(:list, Agent) && obj.cando("add_agent", current_user)
    # 维护总协调人
    arr << [obj.class.icon_action("维护总协调人"), list_kobe_coordinators_path(item_id: obj.id)] if can?(:list, Coordinator) && obj.cando("add_coordinator", current_user)
    # 供应商分级
    arr << [obj.class.icon_action("供应商分级"), classify_kobe_items_path(item_id: obj.id), target: "_blank"] if can?(:classify, obj) && obj.cando("classify", current_user)
    return arr
  end

  def products_btn(obj,only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_product_path(obj), target: "_blank"]  if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_product_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_product_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 冻结
    arr << [obj.class.icon_action("下架"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('下架')}",'#{freeze_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:freeze, obj) && obj.cando("freeze", current_user)
    # 恢复
    arr << [obj.class.icon_action("恢复"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('恢复')}",'#{recover_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:recover, obj) && obj.cando("recover", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_product_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_product_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def agents_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_agent_path(obj), target: "_blank"]  if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_agent_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_agent_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    return arr
  end

  # 总协调人
  def coordinators_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_coordinator_path(obj), target: "_blank"]  if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_coordinator_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_coordinator_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    return arr
  end

  def articles_btn(obj, only_audit = false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), article_path(obj), target: "_blank"]  if can?(:show, obj)
    # 提交
    arr << [obj.class.icon_action("提交"), "#{commit_kobe_article_path(obj)}", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit")
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_article_path(obj)] if can?(:update, obj)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_article_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj)
     # 审核
     audit_opt = [obj.class.icon_action("审核"), "#{audit_kobe_article_path(obj)}"] if can?(:audit, obj) && obj.cando("audit")
     return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def msgs_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), "javascript:read_msg(#{obj.id})"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_msg_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 发布
    arr << [obj.class.icon_action("发布"), commit_kobe_msg_path(obj), method: "post", data: { confirm: "发布后不允许再修改删除，确定发布吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_msg_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
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

  def bid_projects_btn(obj, only_audit = false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_bid_project_path(obj), target: "_blank"]  if can?(:show, obj) && obj.cando("show", current_user)
    # 选择中标人
    arr << [obj.class.icon_action("选择中标人"), choose_kobe_bid_project_path(obj)] if can?(:choose, obj) && obj.cando("choose", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_bid_project_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), "#{commit_kobe_bid_project_path(obj)}", method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_bid_project_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
     # 审核
     audit_opt = [obj.class.icon_action("审核"), "#{audit_kobe_bid_project_path(obj)}"] if can?(:audit, obj) && obj.cando("audit", current_user)
     return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  # 采购计划
  def plan_items_btn(obj)
    arr = []
    # 查看
    arr << [obj.class.icon_action("详细"), kobe_plan_item_path(obj), target: "_blank"]  if can?(:show, obj)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_plan_item_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_plan_item_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_plan_item_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 录入采购计划
    arr << [obj.class.icon_action("录入采购计划"), item_list_kobe_plans_path(item_id: obj.id)] if can?(:item_list, Plan) && obj.cando("add_plan", current_user)
    return arr
  end

  def plans_btn(obj,only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_plan_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_plan_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_plan_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_plan_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_plan_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end


  # 预算审批单
  def budgets_btn(obj,only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_budget_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_budget_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_budget_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_budget_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_budget_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def daily_costs_btn(obj, only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_daily_cost_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_daily_cost_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_daily_cost_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_daily_cost_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_daily_cost_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def fixed_assets_btn(obj, only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_fixed_asset_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_fixed_asset_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_fixed_asset_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    return arr
  end

  def  transfers_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_transfer_path(obj), target: "_blank"]     # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_transfer_path(obj)]    # 删除
    arr << [obj.class.icon_action("提交"), commit_kobe_transfer_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }]
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_transfer_path(obj)}', "#opt_dialog") }]
    return arr
  end

  def faqs_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_faq_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)

    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_faq_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 删除
    arr << [obj.class.icon_action("提交"), commit_kobe_faq_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 提交
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_faq_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)

    # 回复
      arr << [obj.class.icon_action("回复"), reply_kobe_faq_path(obj)] if can?(:reply, obj) && obj.cando("reply", current_user)
    return arr
  end

  def asset_projects_btn(obj, only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_asset_project_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_asset_project_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_asset_project_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_asset_project_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_asset_project_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

  def bid_project_bids_btn(obj)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), obj, target: "_blank"]

    # 报价
    title = current_user.bid_project_bid(obj).new_record? ? "我要报价" : "修改报价"
    arr << [obj.class.icon_action(title), bid_kobe_bid_project_bids_path(bid_project_id: obj.id), target: "_blank"] if can?(:bid, BidProjectBid) && obj.can_bid? && obj.check_user_can_bid?(current_user)


    arr << [obj.class.icon_action("报价明细"), kobe_bid_project_bid_path(current_user.bid_project_bid(obj)), target: "_blank"] if can?(:show, BidProjectBid) && !current_user.bid_project_bid(obj).new_record?
    return arr
  end

  # 协议议价
  def bargains_btn(obj,only_audit=false)
    arr = []
    # 查看详细
    arr << [obj.class.icon_action("详细"), kobe_bargain_path(obj), target: "_blank"] if can?(:show, obj) && obj.cando("show", current_user)
    # 修改
    arr << [obj.class.icon_action("修改"), edit_kobe_bargain_path(obj)] if can?(:update, obj) && obj.cando("edit", current_user)
    # 选择供应商
    arr << [obj.class.icon_action("选择供应商"), choose_kobe_bargain_path(obj)] if can?(:choose, obj) && obj.cando("choose", current_user)
    # 提交
    arr << [obj.class.icon_action("提交"), commit_kobe_bargain_path(obj), method: "post", data: { confirm: "提交后不允许再修改，确定提交吗?" }] if can?(:commit, obj) && obj.cando("commit", current_user)
    # 删除
    arr << [obj.class.icon_action("删除"), "#opt_dialog", "data-toggle" => "modal", onClick: %Q{ modal_dialog_show("#{obj.class.icon_action('删除')}",'#{delete_kobe_bargain_path(obj)}', "#opt_dialog") }] if can?(:update_destroy, obj) && obj.cando("delete", current_user)
    # 报价
    arr << [obj.class.icon_action("报价"), bid_kobe_bargain_path(obj)] if can?(:bid, obj) && obj.cando("bid", current_user)
    # 确认报价结果
    arr << [obj.class.icon_action("确认报价结果"), confirm_kobe_bargain_path(obj)] if can?(:confirm, obj) && obj.cando("confirm", current_user)

    # 审核
    audit_opt = [obj.class.icon_action("审核"), audit_kobe_bargain_path(obj)] if can?(:audit, obj) && obj.cando("audit",current_user)
    return [audit_opt] if audit_opt.present? && only_audit
    return arr
  end

end
