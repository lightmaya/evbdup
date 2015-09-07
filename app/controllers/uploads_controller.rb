# -*- encoding : utf-8 -*-
class UploadsController < ApplicationController
  skip_before_action :verify_authenticity_token, :only => :destroy
  layout false

  def index
    unless params[:master_id].blank?
      @uploads = upload_model.where(["master_id = ?", params[:master_id]])
    else
      @uploads = []
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @uploads.map{|upload| upload.to_jq_upload } }
    end
  end

  def create
    @upload = upload_model.new(form_params)
    # master_id 默认值为 0
    @upload.master_id = params[:master_id] || 0
    respond_to do |format|
      if @upload.save
        write_upload_logs("create")
        format.html {
          render :json => [@upload.to_jq_upload].to_json,
          :content_type => 'text/html',
          :layout => false
        }
        format.json { render json: {files: [@upload.to_jq_upload]}, status: :created, location: "/uploads" }
      else
        format.html { render action: "new" }
        format.json { render json: @upload.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @upload = upload_model.find(params[:id])
    # 加一个权限判断
    if verify_authority(@upload.master_id == params[:master_id].to_i)
      write_upload_logs("destroy")
      @upload.destroy 
    end
    respond_to do |format|
      format.html { redirect_to uploads_path }
      format.json { head :no_content }
    end
  end

  private

  # 从参数中获得附件的Model
  def upload_model
    params[:upload_model].constantize
  end

  # 从参数中获得主表的Model
  def master_model
    params[:upload_model].gsub("Upload","").singularize.constantize
  end

  # 附件参数过滤
  def form_params
    params.require(:upload_file).permit!
  end

  # 在修改表单或者删除附件时记录日志到主表
  def write_upload_logs(action="create")
    unless params[:master_id].blank? || params[:master_id] == 0
      title = action == "create" ? "上传附件" : "删除附件"
      master_obj = master_model.find(params[:master_id])
      logs_remark = prepare_upload_logs_remark([@upload],action)
      unless logs_remark.blank?
        write_logs(master_obj,title,logs_remark) # 写日志
      end
    end
  end

end
