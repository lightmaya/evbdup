# -*- encoding : utf-8 -*-
class ChangeRuleToRuleXmlForRules < ActiveRecord::Migration
  def change    
    rename_column :rules, :rule, :rule_xml 
  end
end
