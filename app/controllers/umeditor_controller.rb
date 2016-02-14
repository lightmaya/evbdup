# -*- encoding : utf-8 -*-
class UmeditorController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def image
    unless params[:upfile]
      render json: {error: 1, message: "上传文件为空"}
      return
    end

    asset = UmeditorFile.new
    asset.data = params[:upfile]
    asset.user_id = current_user.id
    asset.original_name = params[:upfile].original_filename

    # {"url":"/uploads/umeditor_files/image/data/9/02e7211ef09e3df9e65ad4ed3372c809.jpg","name":"02e7211ef09e3df9e65ad4ed3372c809.jpg","title":"pic","type":"image","size":879394,"originalName":"02e7211ef09e3df9e65ad4ed3372c809.jpg","state":"SUCCESS"}
    if asset.save!
      # render json: {url: asset.data.url,
      #               name: asset.store_name,
      #               title: "pic",
      #               type: "image",
      #               size: asset.data.size,
      #               originalName: asset.store_name,
      #               state: "SUCCESS"}
      callback = params[:callback]
      h = {url: asset.data.url,
            name: asset.store_name,
            title: "pic",
            type: asset.data.file.extension.downcase,
            size: asset.data.size,
            originalName: asset.store_name,
            state: "SUCCESS"}

      result = %Q|{"name": "#{asset.store_name}", "originalName": "#{asset.original_name}",
        "size": "#{asset.data.size.to_s}", "state": "SUCCESS", "type": "#{asset.data.file.extension}",
        "url": "#{asset.data.url}"}|
        # result = "{\"name\":\""+ asset.store_name +"\", \"originalName\": \""+ asset.store_name +
        # "\", \"size\": " + asset.data.size.to_s +", \"state\": \""+ "SUCCESS" +
        # "\", \"type\": \"" + asset.data.file.extension.downcase + "\", \"url\": \"" +
        # asset.data.url + "\"}"

      if callback.blank?
        render text: result
      else
        render text: "<script>"+ callback +"(" + result + ")</script>"
      end
    else
      render json: {state: "UNKNOWN"}
    end

  end

end
