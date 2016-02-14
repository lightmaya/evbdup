# -*- encoding : utf-8 -*-
class ArticlesController < JamesController
  def show
    return redirect_to(not_found_path) unless @article = Article.find_by_id(params[:id])
    @article.incr_hit!
  end
end
