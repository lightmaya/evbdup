# -*- encoding : utf-8 -*-
class Kobe::ArticleCatalogsController < KobeController

  skip_before_action :verify_authenticity_token, :only => [:move]
  # protect_from_forgery :except => :index
  before_action :get_article_catalog, :only => [:destroy, :delete]
  layout false, :only => [:edit, :new, :show, :delete]

  skip_authorize_resource :only => [:ztree]

  def index
    # 至少有一个分类才能增删改查
    ArticleCatalog.find_or_create_by(name: "栏目分类", status: ArticleCatalog.effective_status) if ArticleCatalog.count == 0
    @article_catalog = ArticleCatalog.find_by(id: params[:id]) if params[:id].present?
  end

  def new
    @article_catalog.parent_id = params[:pid] unless params[:pid].blank?
    @myform = SingleForm.new(ArticleCatalog.xml, @article_catalog, { form_id: "article_catalog_form", action: kobe_article_catalogs_path, grid: 2 })
  end

  def edit
    @myform = SingleForm.new(ArticleCatalog.xml, @article_catalog, { form_id: "article_catalog_form", action: kobe_article_catalog_path(@article_catalog), method: "patch", grid: 2 })
  end

  def show
    @arr  = []
    @arr << { title: "详细信息", icon: "fa-info", content: show_obj_info(@article_catalog, ArticleCatalog.xml) }
    @arr << { title: "历史记录", icon: "fa-clock-o", content: show_logs(@article_catalog) }
  end

  def create
    article_catalog = create_and_write_logs(ArticleCatalog, ArticleCatalog.xml)
    if article_catalog
      redirect_to kobe_article_catalogs_path(id: article_catalog)
    else
      render 'index'
    end
  end

  def update
    if update_and_write_logs(@article_catalog, ArticleCatalog.xml)
      redirect_to kobe_article_catalogs_path(id: @article_catalog)
    else
      render 'index'
    end
  end

  # 删除
  def delete
    render partial: '/shared/dialog/opt_liyou', locals: { form_id: 'delete_article_catalog_form', action: kobe_article_catalog_path(@article_catalog), method: 'delete' }
  end

  def destroy
    @article_catalog.change_status_and_write_logs("删除", stateless_logs("删除",params[:opt_liyou],false))
    tips_get("删除成功。")
    redirect_to kobe_article_catalogs_path(id: @article_catalog.parent_id)
  end

  def move
    ztree_move(ArticleCatalog)
  end

  def ztree
    ztree_nodes_json(ArticleCatalog)
  end

  private

    def get_article_catalog
      cannot_do_tips unless @article_catalog.present? && @article_catalog.cando(action_name)
    end

end
