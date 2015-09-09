# -*- encoding : utf-8 -*-
class Kobe::ArticlesController < KobeController

  def index
    # authorize! :index, Article, :message => "您没有相关权限！"
    params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = Article.where(get_conditions("artilces")).ransack(params[:q]) 
    @articles = @q.result.includes(:author).page params[:page]
  end

  def show
  end

  def new
    @article.username = current_user.name 
    @article.status = 2
    @myform = SingleForm.new(Article.xml, @article, 
      { form_id: "article_form", upload_files: true, action: kobe_articles_path,
        title: '<i class="fa fa-pencil-square-o"></i> 新增公告', grid: 2  
      })
  end

  def edit
  end

  def create
    article = create_and_write_logs(Article, Article.xml)
    redirect_to kobe_articles_path
  end

  def update
    if @article.update(my_params)
      tips_get("操作成功。")
      redirect_to kobe_articles_path
    else
      flash_get(@article.errors.full_messages)
      render 'edit'
    end
  end

  # 批处理
  def batch_task
    render :text => params[:grid].to_s
  end

  private  

    # 只允许传递过来的参数
    def my_params  
      params.require(:articles).permit(:title, :new_days, :top_type, 
        :access_permission, :content)  
    end
end
