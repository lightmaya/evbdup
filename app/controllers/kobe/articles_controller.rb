# -*- encoding : utf-8 -*-
class Kobe::ArticlesController < KobeController

  def index
    # authorize! :index, Article, :message => "您没有相关权限！"
    params[:q][:user_id_eq] = current_user.id unless current_user.admin?
    @q = Article.where(get_conditions("articles")).ransack(params[:q]) 
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
    @myform = SingleForm.new(Article.xml, @article, { form_id: "article_form", action: kobe_article_path(@article), method: "patch", grid: 2 })
  end

  def create
    article = create_and_write_logs(Article, Article.xml)
    redirect_to kobe_articles_path
  end

  def update
    update_and_write_logs(@article, Article.xml)
    redirect_to kobe_articles_path
  end

  # 批处理
  def batch_task
    render :text => params[:grid].to_s
  end

    # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_article_form', action: kobe_article_path(@article), method: 'delete' }
  end

  def destroy
    @article.change_status_and_write_logs("已删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_articles_path
  end

  private  

    # 只允许传递过来的参数
    def my_params  
      params.require(:articles).permit(:title, :new_days, :top_type, 
        :access_permission, :content)  
    end
end
