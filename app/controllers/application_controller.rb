class ApplicationController < ActionController::Base
  # reset captcha code after each request for security
  after_action :reset_last_captcha_code!


  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # 开发给view层用的方法
  helper_method :current_user, :signed_in?, :redirect_back_or, :cando_list

  before_action :store_location
  # cancan 权限校验
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to errors_path, :alert => exception.message
    # render :file => "#{Rails.root}/public/403.html", :status => 403, :layout => false
  end

  # 当前用户
  def current_user
    remember_token = User.encrypt(cookies[:remember_token])
    User.current ||= User.find_by(remember_token:remember_token) 
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

  protected

    # 生产ztree的json
    def ztree_json(obj_class)
      render :json => obj_class.get_json(params[:name])
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
