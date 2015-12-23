# -*- encoding : utf-8 -*-
class Kobe::TransfersController < KobeController

	def index
		@q = Transfer.ransack(params[:q])
    @transfers = @q.result.page params[:page]
	end

	 def new
  	@transfer.dep_name = current_user.real_department.name
    @transfer.dep_man = current_user.name
    @transfer.dep_tel = current_user.tel
    @transfer.dep_mobile = current_user.mobile
    @transfer.dep_addr = current_user.department.address
    slave_objs = [TransferItem.new(transfer_id: @transfer.id)]
    @myform = MasterSlaveForm.new(Transfer.xml,TransferItem.xml,@transfer,slave_objs,{form_id: 'new_transfer', upload_files: true, title: '<i class="fa fa-pencil-square-o"></i> 单位信息',action: kobe_transfers_path, show_total: true, grid: 3},{title: '产品明细', grid: 4})
  end

   def create
    other_attrs = { department_id: current_user.department.id, dep_code: current_user.real_dep_code, user_id: current_user.id, name: create_name }
    @transfer = create_msform_and_write_logs(Transfer, Transfer.xml, TransferItem, TransferItem.xml, {:action => "下单", :master_title => "基本信息",:slave_title => "产品信息"}, other_attrs)
    redirect_to kobe_transfers_path
  end

   def update
    update_msform_and_write_logs(@transfer, Transfer.xml, TransferItem, TransferItem.xml, {:action => "修改项目信息", :slave_title => "产品信息"}, {name: create_name})
    redirect_to kobe_transfers_path
  end

  def edit
    slave_objs = @transfer.items.blank? ? [@transfer.items.build] : @transfer.items
    @myform = MasterSlaveForm.new(Transfer.xml,TransferItem.xml , @transfer, slave_objs,{form_id: 'new_transfer', title: "<i class='fa fa-wrench'></i> 修改项目信息" , action: kobe_transfer_path(@transfer), method: "patch", upload_files: true, show_total: true, grid: 3},{title: '产品明细', grid: 4})
  end

  def show
    obj_contents = show_obj_info(@transfer,Transfer.xml,{grid: 3})
    @transfer.items.each_with_index do |p, index|
    obj_contents << show_obj_info(p,TransferItem.xml,{title: "产品明细 ##{index+1}", grid: 3})
    end
    @arr  = []
    @arr << {title: "详细信息", icon: "fa-info", content: obj_contents}
    @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@transfer)}
    @arr << {title: "历史记录", icon: "fa-clock-o", content: show_logs(@transfer)}
  end

  # 提交
  def commit
    @transfer.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false))
    # 插入日常费用审核的待办事项
    tips_get("提交成功！")
    redirect_back_or
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_transfer_form', action: kobe_transfer_path(@transfer), method: 'delete' }
  end

  def destroy
    @transfer.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_back_or request.referer
  end

  private

       # 根据品目创建项目名称
    def create_name
      category = {}
      transfer_type = params[:transfers][:total].to_i==0 ? '无偿划转'  : '协议转让'
      params[:transfer_items][:category_name].each  do |k,v|
        num = params[:transfer_items][:num][k]
        unit = params[:transfer_items][:unit][k]
        unless  category.has_key? (v)
          category[v]=[num,unit]
        else
          num = category[v][0].to_i + num.to_i
          category[v]=[num,unit]
        end
      end
      arr=[]
      category.each do  |k,v|
        arr<< "#{k}#{v[0]}#{v[1]}"
      end
      return "#{current_user.real_department.name}#{transfer_type}#{arr.join('、')}"
    end




end
