# -*- encoding : utf-8 -*-

Date::DATE_FORMATS[:default] = "%Y-%m-%d"
Time::DATE_FORMATS[:default] = "%Y-%m-%d %H:%M:%S"

class String
  def no_chinese?
    (self =~ /[\u4e00-\u9fa5]/).nil?
  end

  def to_utf8
    encode("UTF-8", :undef => :replace, :replace => "?", :invalid => :replace).chars.select{|i| i.valid_encoding?}.join
  end

  def to_gbk
    encode("GBK", :undef => :replace, :replace => "?", :invalid => :replace).chars.select{|i| i.valid_encoding?}.join
  end

  def to_gbk!
    return to_gbk
  end

  def to_utf8!
    return to_utf8
  end

  def find(regex)
    self.scan(regex).flatten.first.presence
  end

  def truncate_c(length) 
    ret = '' 
    count = 0 
    self.scan(/./u).each do |c| 
      ret << c 
      count += (c.length == 1 ? 0.5 : 1) 
      break if count >= length 
    end 
    return ret 
  end

  def pure_text(clean_blank = 2)
    return_text = Sanitize.clean(self.to_s)
    return_text.gsub!(/\s+/, '') if clean_blank > 0
    return_text.gsub!(/[   　]/, '') if clean_blank > 1
    chn_num = ["０", "１", "２", "３", "４", "５", "６", "７", "８", "９"]
    eng_num = %w{0 1 2 3 4 5 6 7 8 9}
    chn_num.each do |cn| 
      if return_text.include?(cn)
        return_text.gsub!(cn, eng_num[chn_num.index(cn)])
      end
    end
    return_text
  end

  # 只留下中文，英文和数字
  def cen 
    self.gsub(/[^a-zA-Z0-9\u4e00-\u9fa5]/, "")
  end
end

class Time
  # 返回时间int型, 比如20140311
  def self.index_date_now
    self.now.strftime('%Y%m%d').to_i
  end

  # 返回时间int型, 比如20140311
  def self.index_date_yesterday
    self.now.yesterday.strftime('%Y%m%d').to_i
  end

  # 返回时间整形
  def index_date
    self.strftime('%Y%m%d').to_i
  end

  def index_day
    index_date
  end

  # 返回month整形
  def index_month
    self.strftime('%Y%m').to_i
  end

  # 返回week整形
  def index_week 
    year = self.strftime('%Y').to_i
    week = self.strftime('%W').to_i    
    num = Date.commercial( year.to_i, 52, 1 ).strftime('%W')
    if num.to_i == 52
      if week == 0
        return ((year-1).to_s << "52").to_i
      elsif week == 53
        return ((year+1).to_s << "01").to_i
      else 
        return self.strftime('%Y%W').to_i 
      end                    
    else
      if week + 1 == 53
        return ((year+1).to_s << "01").to_i
      else 
        return self.strftime('%Y%W').to_i + 1
      end              
    end  
  end

  # 返回季度整形数字
  def index_quarter
    quarter = case self.strftime('%m').to_i
    when 1,2,3 then 1
    when 4,5,6 then 2
    when 7,8,9 then 3
    when 10,11,12 then 4
    end
    return (self.strftime('%Y') << "0" << quarter.to_s).to_i
  end
end

# 周的日期时间
# num 201430 2014年第30周 从零开始
#
# week_range(201432)
# => "0811-0817"
# week_range(201432,true)
# => "20140811-20140817"
def week_range(num, need_year=false)
  week = num.to_s[4..5].to_i 
  year = num.to_s[0..3].to_i
  begin
    monday = Date.commercial( year, week, 1 ).to_time
    sunday = Date.commercial( year, week, 7 ).to_time
  rescue => e
    return ''
  end
  if need_year
    return "#{monday.index_date}-#{sunday.index_date}" 
  end
  "#{monday.strftime('%m%d')}-#{sunday.strftime('%m%d')}" 
end 

def week_range_w(num, need_year=false)
  "#{num.to_i + 1}(#{week_range(num, need_year)})"
end

# 通用日志记录
ActiveRecord::Base.send(:include, LvUp)

