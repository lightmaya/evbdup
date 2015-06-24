# -*- encoding : utf-8 -*-
class Kobe::SuggestionsController < KobeController

  skip_before_action :verify_authenticity_token, :only => [:destroy, :mark_as_read, :mark_as_unread]
  before_action :get_suggestion, :only => [:show, :destroy, :mark_as_read, :mark_as_unread]

  def show

  end

  def create
    create_and_write_logs(Suggestion, Suggestion.xml)
    redirect_back_or
  end

  def list
    @suggestions = Suggestion.where(get_conditions).page params[:page]
  end

  def destroy
    logs = prepare_logs_content(@suggestion,"删除")
    @suggestion.change_status_and_write_logs("已删除",logs)
    redirect_back_or list_kobe_suggestions_path
  end

  # 标记为已读
  def mark_as_read
    logs = prepare_logs_content(@suggestion,"标记为已读")
    @suggestion.change_status_and_write_logs("已读",logs)
    redirect_back_or list_kobe_suggestions_path
  end

  # 标记为未读
  def mark_as_unread
    logs = prepare_logs_content(@suggestion,"标记为未读")
    @suggestion.change_status_and_write_logs("未读",logs)
    redirect_back_or list_kobe_suggestions_path
  end

  # 批量处理(删除、标记为已读、标记为未读)
  def batch_opt
    unless params[:check].blank?
      case params[:batch_opt]
      when "delete"
        status = Suggestion.get_status_attributes("已删除")[1]
        logs = stateless_logs("删除")
      when "read"
        status = Suggestion.get_status_attributes("已读")[1]
        logs = stateless_logs("标记为已读")
      when "unread"
        status = Suggestion.get_status_attributes("未读")[1]
        logs = stateless_logs("标记为未读")
      when "clean"
        Suggestion.destroy_all(id: params[:check].to_a)
      end
      Suggestion.batch_change_status_and_write_logs(params[:check].to_a, status, logs)
    end 
    redirect_back_or list_kobe_suggestions_path
  end

  # 创建附件
  def create_upload
    @upload = SuggestionsUpload.new(upload_params)
    respond_to do |format|
      if @upload.save
        format.html {
          render :json => [@upload.to_jq_upload].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json { render json: {files: [@upload.to_jq_upload]}, status: :created, location: @upload }
      else
        format.html { render action: "new" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  # 删除附件
  def destroy_upload
    @upload = SuggestionsUpload.find(params[:id])
    @upload.destroy

    respond_to do |format|
      format.html { redirect_to uploads_url }
      format.json { head :no_content }
    end
  end

  private  

    def get_suggestion
      @suggestion = Suggestion.find(params[:id]) unless params[:id].blank? 
    end


    def upload_params
      params.require(:upload).permit!
    end

end
