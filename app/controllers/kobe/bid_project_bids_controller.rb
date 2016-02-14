# -*- encoding : utf-8 -*-
class Kobe::BidProjectBidsController < KobeController
  before_filter :find_bid_project, only: [:bid, :update_bid]

  def bid
    slave_objs = current_user.bid_item_bids(@bid_project).presence || @bid_project.items.map{|item| BidItemBid.new(bid_item_id: item.id, bid_project_id: @bid_project.id, brand_name: item.brand_name, xh: item.xh, req: item.req, remark: item.remark) }
    @ms_form = MasterSlaveForm.new(BidProjectBid.xml, BidItemBid.xml, @bid_project_bid, slave_objs,
      {title: "报价", upload_files: true, action: update_bid_kobe_bid_project_bids_path(bid_project_id: @bid_project.id), show_total: true, grid: 4},
      {title: '产品明细', grid: 4, modify: false}
      )
  end

  def update_bid
    other_attrs = { com_name: current_user.real_department.name, bid_time: Time.now, department_id: current_user.department.id}
    info = @bid_project_bid.new_record? ? "报价" : "修改报价"
    @bid_project_bid = create_or_update_msform_and_write_logs(@bid_project_bid, BidProjectBid.xml, BidItemBid, BidItemBid.xml, {:action => "报价", :master_title => "基本信息", :slave_title => "产品信息"}, other_attrs)
    write_logs(@bid_project, "#{info}", "[#{current_user.real_department.name}]#{info}成功！")
    redirect_to action: :index
  end

  def show
    project = @bid_project_bid.bid_project
    # 如果是报价单位 或者是项目截止后 本竞价项目的上级单位 才可以显示报价
    if current_user.real_department.is_ancestors?(@bid_project_bid.department_id) || (project.is_end? && current_user.real_department.is_ancestors?(project.department_id))
      obj_contents = show_obj_info(@bid_project_bid, BidProjectBid.xml, {title: "基本信息", grid: 3})
      @bid_project_bid.items.each_with_index do |item, index|
        obj_contents << show_obj_info(item, BidItemBid.xml, {title: "产品明细 ##{index+1}", grid: 3})
      end
      obj_contents << show_total_part(@bid_project_bid.total)

      @arr  = []
      @arr << { title: "详细信息", icon: "fa-info", content: obj_contents }
      @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@bid_project_bid) }
    else
      cannot_do_tips
    end
  end

  def index
    params[:flag] ||= "1"
    clazz = case params[:flag]
    when "1" # 可报价
      @panel_title = "可报价的竞价项目"
      BidProject.can_bid
    when "2" # 已投标
      @panel_title = "已投标的竞价项目"
      params[:q][:bid_project_bid_user_id_eq] = current_user.id
      BidProject
    when "3" # 已中标
      @panel_title = "已中标的竞价项目"
      params[:q][:bid_project_bid_id_in] = current_user.bid_project_bids.map(&:id)
      BidProject
    end
    @q = clazz.ransack(params[:q])
    @bid_projects = @q.result.includes(:bid_item_bids).page params[:page]
  end

  private

    def find_bid_project
      @bid_project = BidProject.find_by_id(params[:bid_project_id])
      return redirect_to not_found_path unless @bid_project
      return redirect_to bid_project_path(@bid_project) unless @bid_project.can_bid?
      unless @bid_project.check_user_can_bid?(current_user)
        flash_get("您不是指定的入围供应商，无法参与报价！")
        return redirect_to :back
      end
      @bid_project_bid = current_user.bid_project_bid(@bid_project)
    end

end
