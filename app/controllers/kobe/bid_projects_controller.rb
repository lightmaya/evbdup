# -*- encoding : utf-8 -*-
class Kobe::BidProjectsController < KobeController
  skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]
  before_action :get_show_arr, :only => [:show, :audit, :choose]
  before_filter :check_bid_project, :except => [:index, :bid, :new, :create, :list]

  def index
    @q = BidProject.find_all_by_buyer_code(current_user.real_dep_code).where(get_conditions("bid_projects")).ransack(params[:q])
    @bid_projects = @q.result.includes([:bid_project_bids]).page params[:page]
  end

  def show
  end

  # def bid
  # end

  def audit
  end

  def choose
    # 默认第一中标人
    @bid_project.bid_project_bid_id = @bpbs.first.try(:id)
  end

  def update_choose
    #W status id reason
    # 选择中标人之后转换到网上竞价结果的流程
    @bid_project.update(rule_id: Rule.find_by(yw_type: 'wsjj_jg').try(:id), rule_step: 'start')
    # 保存参数
    @bid_project.update(params.require(:bid_project).permit!)
    @bid_project.bid_project_bid.update(is_bid: true) if @bid_project.bid_project_bid.present?
    # 写日志
    # write_logs(@bid_project, BidProject.get_status_attributes(@bid_project.status, 1)[0], @bid_project.reason)
    remark = "#{params[:choose_who]}成功！"
    remark << "选择[#{@bid_project.bid_project_bid.com_name}]为中标单位。" if @bid_project.bid_project_bid.present?
    remark << "操作理由：#{@bid_project.reason}" if @bid_project.reason.present?
    logs = stateless_logs("选择中标人", remark, false)
    @bid_project.change_status_and_write_logs("选择中标人", logs, @bid_project.commit_params, false)
    @bid_project.reload.create_task_queue
    tips_get(remark)
    redirect_to action: :index
    # @bid_project.update(params[:bid_project].permit(:bid_project_bid_id, :reason))
  end

  def update_audit
    save_audit(@bid_project)
    # 确定中标人
    if @bid_project.status == 23
      # Rufus::Scheduler.new.in "1s" do
      @bid_project.send_to_order
      #   ActiveRecord::Base.clear_active_connections!
      # end
    end
    redirect_to list_kobe_bid_projects_path(r: @bid_project.rule.try(:id))
  end

  def list
    @rule = Rule.find_by(id: params[:r]) if params[:r].present?
    to_do_list_ids = @rule.create_rule_objs.map{ |e| e.attributes["to_do_id"] }.uniq if @rule.present?
    arr = to_do_list_ids.present? ? [["task_queues.to_do_list_id in (?) ", to_do_list_ids]] : []
    @bid_projects = audit_list(BidProject, arr)
  end

  # 提交
  def commit
    @bid_project.change_status_and_write_logs("提交", stateless_logs("提交","提交成功！", false), @bid_project.commit_params, false)
    @bid_project.reload.create_task_queue
    tips_get("提交成功。")
    redirect_to action: :index
  end

  def new
    @bid_project.buyer_dep_name = @bid_project.invoice_title = current_user.real_department.name
    @bid_project.buyer_name = current_user.name
    @bid_project.buyer_phone = current_user.tel
    @bid_project.buyer_mobile = current_user.mobile
    # @bid_project.buyer_email = current_user.email
    @bid_project.buyer_add = current_user.department.address

    slave_objs = [@bid_project.items.build]
    @ms_form = MasterSlaveForm.new(BidProject.xml(true), BidItem.xml, @bid_project, slave_objs,
      { form_id: "bid_project_form", action: kobe_bid_projects_path, upload_files: true,
        # upload_files_name: "bid_project",
        title: '<i class="fa fa-pencil-square-o"></i> 新增竞价', grid: 3},
        {title: '产品明细', grid: 3}
      )
  end

  def edit
    slave_objs = @bid_project.items.blank? ? [@bid_project.items.build] : @bid_project.items
    @ms_form = MasterSlaveForm.new(BidProject.xml(true), BidItem.xml, @bid_project,slave_objs,{upload_files: true, title: '<i class="fa fa-wrench"></i> 修改竞价',action: kobe_bid_project_path(@bid_project), method: "patch", grid: 3},{title: '产品明细', grid: 3})
  end

  def create
    other_attrs = {department_id: current_user.department.id, department_code: current_user.real_dep_code, name: get_project_name }
    obj = create_msform_and_write_logs(BidProject, BidProject.xml(true), BidItem, BidItem.xml, { :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
    redirect_to kobe_bid_projects_path
  end

  def update
    update_msform_and_write_logs(@bid_project, BidProject.xml(true), BidItem, BidItem.xml, {:action => "修改竞价", :slave_title => "产品明细"})
    redirect_to kobe_bid_projects_path
  end

  # 批处理
  # def batch_task
  #   render :text => params[:grid].to_s
  # end

    # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_bid_project_form', action: kobe_bid_project_path(@bid_project), method: 'delete' }
  end

  def destroy
    @bid_project.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_bid_projects_path
  end

  private

    # 获取审核的menu_ids
    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("BidProject|list")
    end

    def get_show_arr
      @arr  = []
      obj_contents = show_obj_info(@bid_project, BidProject.xml(current_user.real_department.is_ancestors?(@bid_project.department_id)), {title: "基本信息", grid: 3})
      @bid_project.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item, BidItem.xml, {title: "产品明细 ##{index+1}", grid: 3})
      end
      @bpbs = @bid_project.bid_project_bids.order("bid_project_bids.total ASC, bid_project_bids.bid_time ASC")
      @arr << { title: "详细信息", icon: "fa-info", content: obj_contents }

      @arr << get_budget_hash(@bid_project.budget, @bid_project.department_id)
      # budget = @bid_project.budget
      # if budget.present? && current_user.real_department.is_ancestors?(@bid_project.department_id)
      #   budget_contents = show_obj_info(budget, Budget.xml)
      #   budget_contents << show_uploads(budget)
      #   @arr << { title: "预算审批单", icon: "fa-paperclip", content: budget_contents }
      # end
      @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@bid_project) }
      @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@bid_project, @bid_project.can_bid?) }

    end
    # 只允许传递过来的参数
    # def my_params
    #   params.require(:bid_projects).permit(:title, :new_days, :top_type,
    #     :access_permission, :content)
    # end

    def get_project_name
      category_names = params[:bid_items][:category_name].values.uniq.join("、")
      "#{params[:bid_projects][:buyer_dep_name]}#{category_names}竞价项目"
    end

    # 只允许自己操作自己的项目
    def check_bid_project
      # @bid_project = current_user.department.is_zgs? ? BidProject.find_by_id(params[:id]) : current_user.bid_projects.find_by_id(params[:id])
      # return redirect_to not_fount_path unless @bid_project
      cannot_do_tips unless @bid_project.present? && @bid_project.cando(action_name,current_user)
      audit_tips  if ['audit', 'update_audit'].include?(action_name) && !can_audit?(@bid_project,@menu_ids)
    end

end
