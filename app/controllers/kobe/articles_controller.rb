# -*- encoding : utf-8 -*-
class Kobe::ArticlesController < KobeController
  skip_before_action :verify_authenticity_token, :only => [:commit]
  before_action :get_show_arr, :only => [:audit, :show]
  before_action :get_audit_menu_ids, :only => [:list, :audit, :update_audit]

  def index
    # authorize! :index, Article, :message => "您没有相关权限！"
    # params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = Article.where(get_conditions("articles")).ransack(params[:q]) 
    @articles = @q.result.includes([:author, :catalogs]).page params[:page]
  end

  def show
  end

  def audit

  end

  def update_audit
    save_audit(@article)
    # 如果需要审核 更新发布时间 
    @article.publish_time!
    redirect_to list_kobe_articles_path
  end

  def list
    @articles = audit_list(Article)
    # arr = []
    # arr << ["articles.status = ? ", Article.audit_status]
    # arr << ["(task_queues.user_id = ? or task_queues.menu_id in (#{@menu_ids.join(",") }) )", current_user.id]
    # arr << ["task_queues.dep_id = ?", current_user.real_department.id]
    # cdt = get_conditions("articles", arr)
    # @q =  Article.joins(:task_queues).where(cdt).ransack(params[:q]) 
    # @articles = @q.result(distinct: true).page params[:page]
  end

  # 注册提交
  def commit
    @article.change_status_and_write_logs("提交",
      stateless_logs("提交","提交成功！", false),
      @article.commit_params, false)
    # 如果不需要审核 更新发布时间 
    @article.publish_time!
    @article.reload.create_task_queue
    tips_get("提交成功。")
    redirect_to kobe_articles_path(id: @article)
  end

  def new
    @article.username = current_user.name 
    @myform = SingleForm.new(Article.xml, @article, 
      { form_id: "article_form", action: kobe_articles_path,
        title: '<i class="fa fa-pencil-square-o"></i> 新增公告', grid: 2  
      })

    # xml默认调用obj.class.xml
    # title根据obj.new_record?和model中定义的Mname自动生成
    # action根据obj.new_record?自动生成
    @myform = OneForm.new(@article)
  end

  def edit
    @myform = SingleForm.new(Article.xml, @article, { form_id: "article_form", action: kobe_article_path(@article), method: "patch", grid: 2 })
  end

  def create
    article = create_and_write_logs(Article, Article.xml)
    redirect_to kobe_articles_path
  end

  def update
    update_and_write_logs(@article, Article.xml, { action: '修改公告' }, { status: 0 })
    redirect_to kobe_articles_path
  end

  # 批处理
  # def batch_task
  #   render :text => params[:grid].to_s
  # end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_article_form', action: kobe_article_path(@article), method: 'delete' }
  end

  def destroy
    @article.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_articles_path
  end

  private  

    # 获取审核的menu_ids
    def get_audit_menu_ids
      @menu_ids = Menu.get_menu_ids("Article|list")
    end

    def get_show_arr
      @arr  = []
      @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@article, Article.xml) }
      # @arr << { title: "附件", icon: "fa-paperclip", content: show_uploads(@article, { is_picture: true }) }
      @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@article) }
    end

    # 只允许传递过来的参数
    # def my_params  
    #   params.require(:articles).permit(:title, :new_days, :top_type, 
    #     :access_permission, :content)  
    # end
end
