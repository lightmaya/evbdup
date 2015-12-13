class Kobe::FaqsController < KobeController

  before_action :get_faq, :except => [:index, :new, :create, :yjjy_list, :get_catalog]
  skip_before_action :verify_authenticity_token, :only => [:commit, :get_catalog]
  skip_load_and_authorize_resource :only => :get_catalog

	def index
		@q = Faq.ransack(params[:q]) 
    @faqs = @q.result.status_not_in(404).page params[:page]
	end


  def new 
    if params[:catalog]=='yjjy'
      @faq.ask_user_name = current_user.name
      @faq.ask_dep_name = current_user.real_department.name
    end 
    type = Dictionary.faq_catalog[params[:catalog]]
    @myform = SingleForm.new(Faq.xml(params[:catalog]), @faq, { form_id: "faq_form", upload_files: true , title: "<i class='fa fa-pencil-square-o'></i> #{type}", action: kobe_faqs_path(catalog: params[:catalog]), grid: 3 })
  end


  def create
    create_and_write_logs(Faq, Faq.xml(params[:catalog]),{},{catalog: params[:catalog], ask_user_id: current_user.id })
    redirect_to kobe_faqs_path
  end
  
  def edit
    type = Dictionary.faq_catalog[@faq.catalog]
    @myform = SingleForm.new(Faq.xml(@faq.catalog), @faq, { form_id: "faq_form", upload_files: true , title: "<i class='fa fa-pencil-square-o'></i> #{type}", action: kobe_faq_path(@faq), method: "patch", grid: 3 })
  end

  def update 
    update_and_write_logs(@faq, Faq.xml)
    redirect_to kobe_faqs_path
  end

  def show 
    @arr  = []
    obj_contents = show_obj_info(@faq,Faq.xml,{title: "基本信息" , grid: 3})
    @arr << { title: "详细信息", icon: "fa-info", content: obj_contents }
    @arr << {title: "附件", icon: "fa-paperclip", content: show_uploads(@faq)}
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@faq)}
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_faq_form', action: kobe_faq_path(@faq), method: 'delete' }
  end

  def destroy
    @faq.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_faqs_path
  end

  def get_catalog
    render layout: false
  end

  def commit
    @faq.change_status_and_write_logs("提交",stateless_logs("提交","提交成功！", false))
    # 插入日常费用审核的待办事项
    tips_get("提交成功！")
    redirect_back_or
  end

  def reply
    
  end

  def update_reply
     status = @faq.change_status_hash["回复"][@faq.status]
     @faq.update(content: params[:reply], status: status )
     write_logs(@faq, '回复')
     redirect_to kobe_faqs_path
  end

  def yjjy_list
     @q = current_user.yjjy.ransack(params[:q]) 
     @faqs = @q.result.status_not_in(404).page params[:page]
  end

  #是否有权限操作项目
  def get_faq
    cannot_do_tips unless @faq.present? && @faq.cando(action_name,current_user)
  end

end
