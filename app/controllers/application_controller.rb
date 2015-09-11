# -*- encoding : utf-8 -*-
class ApplicationController < ActionController::Base
  # reset captcha code after each request for security
  # after_action :reset_last_captcha_code!


  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # 开发给view层用的方法
  helper_method :current_user, :signed_in?, :redirect_back_or, :cando_list

  before_action :store_location

  before_action :init_params_search

  # cancan 权限校验
  rescue_from CanCan::AccessDenied do |exception|
    flash_get(exception.message)
    respond_to do |format|
      format.json { render text: exception.message }
      format.html { redirect_to current_user.present? ? main_path : root_path}
    end
    # redirect_to errors_path, :alert => exception.message
    # render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
  end

  # 当前用户
  def current_user
    remember_token = User.encrypt(cookies[:remember_token])
    @current_user ||= User.find_by(remember_token:remember_token) 
  end
 
  # 是否登录?
  def signed_in?
    !current_user.nil?
  end
  
  # 后退页面
  def redirect_back_or(default=nil)
    redirect_to(default || session[:return_to] || root_path)
    session.delete(:return_to)
  end

  # 查询初始化参数 
  def init_params_search
    params[:q] ||= {}
  end

  protected

    # 生成带搜索的ztree的json 用于下拉框选择
    def ztree_box_json(obj_class)
      name = params[:ajax_key]
      if name.blank?
        nodes = obj_class.attribute_method?("status") ? obj_class.where.not(status: 404) : obj_class.all
      else
        cdt = obj_class.attribute_method?("status") ? "and a.status != 404 and b.status != 404" : ""
        sql = "SELECT DISTINCT a.id,a.name,a.ancestry FROM #{obj_class.to_s.tableize} a INNER JOIN  #{obj_class.to_s.tableize} b ON (FIND_IN_SET(a.id,REPLACE(b.ancestry,'/',',')) > 0 OR a.id=b.id OR (LOCATE(CONCAT(b.ancestry,'/',b.id),a.ancestry)>0)) WHERE b.name LIKE ? #{cdt} ORDER BY a.ancestry"
        nodes = obj_class.find_by_sql([sql,"%#{name}%"])
      end
      render :json => obj_class.get_json(nodes)
    end

    # 生成不带搜索的ztree的json 用于维护树形结构 例如单位维护 菜单维护 角色维护等
    # 如果node为空 生成树的json 取所有状态不是已删除的节点 例如 menu、category等
    # 如果node不为空 取node和他的子孙们 例如 department 
    def ztree_nodes_json(obj_class, node='')
      if node.blank?
        nodes = obj_class.attribute_method?("status") ? obj_class.where.not(status: 404) : obj_class.all
      else
        nodes = node.subtree.where.not(status: 404)
      end
      render :json => obj_class.get_json(nodes)
    end

    # 设置后退页面
    def store_location
      session[:return_to] = request.fullpath if request.get?
    end

    # 需要登录
    def request_signed_in!
      unless signed_in?
        flash_get '请先登录!'
        redirect_to sign_in_users_path
      end
    end

    # 验证身份
    def verify_authority(boolean)
      return current_user.admin? ? true : boolean
    end

    #着重提示，等用户手动关闭
    def flash_get(message)
      flash[:notice] = message
    end

    #普通提示，自动关闭
    def tips_get(message)
      flash[:tips] = message
    end

    # 发送邮件
    def send_email(email,title,content)
      # 这里是发送邮件的代码，暂缺
    end

    # 验证表单remote  true：通过验证，false：已存在
    def valid_remote(obj_class,cdt)
      return obj_class.where(cdt).blank? ? true :false
    end

    include SaveXmlForm

end
