# -*- encoding : utf-8 -*-
class ArticlesController < JamesController
  def show
    return redirect_to(errors_path(no: 404)) unless @article = Article.find_by_id(params[:id])
    @article.incr_hit!
  end
end
