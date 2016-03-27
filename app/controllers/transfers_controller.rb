# -*- encoding : utf-8 -*-
class  TransfersController < JamesController
  def show
    return redirect_to(errors_path(no: 404)) unless @transfer = Transfer.find_by_id(params[:id])

    @obj_contents = info_html(@transfer, Transfer.xml, {title: "基本信息", grid: 3})
    @transfer.items.each_with_index do |item, index|
      @obj_contents << info_html(item, TransferItem.xml, {title: "产品明细 ##{index+1}", grid: 4})
    end
  end
end
