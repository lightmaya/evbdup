# -*- encoding : utf-8 -*-
module KobeHelper

  # 日期筛选,用于list列表页面
  def date_filter(arr=[])
    if arr.blank?
      arr = [
        ["最近三个月","3m"],
        ["最近半年","6m"],
        ["最近一年","1y"],
        ["今年以内","ty"],
        ["全部时间","all"]
      ]
    end
    return head_filter("date_filter",arr)
  end

  # 状态筛选,用于list列表页面
  def status_filter(model,action='')
    arr = model.status_filter(action).push(["全部状态","all"])
    return head_filter("status_filter",arr)
  end

  # 更多操作,用于list列表页面,主要指批量操作的下拉按钮
  # 也可设置多个按钮组,例如增加和更多操作两个按钮 btn_count=2
  def more_actions(arr,btn_count=1)
    btn_count = btn_count.to_i unless btn_count.is_a?(Integer)
    str = ""
    if btn_count > 1
      str << btn_group(arr[0...btn_count-1], false)
      arr = arr[btn_count-1, arr.length]
    end
    str << head_filter("more_actions",arr.push(["更多操作", "all"]))
    return raw str.html_safe
  end
  
end