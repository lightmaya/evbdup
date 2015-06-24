# -*- encoding : utf-8 -*-
class HomeController < JamesController
  # layout "application" ,:only => :test

    def index
        trial and error
    end
    
    def ajax_test
        render :text => "这是来自ajax的内容。"
    end

    def json_test
        ztree_json(Menu)
    end

    def form_test
    end

end
