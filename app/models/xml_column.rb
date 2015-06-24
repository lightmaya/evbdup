# -*- encoding : utf-8 -*-
class XmlColumn
	attr_accessor :attributes
	def initialize
		# @attributes = { name: self.name, column: self.column, data_type: self.data_type, rule: self.rule, data: self.data, is_required: self.is_required, hint: self.hint, placeholder: self.placeholder }
		# tmp = self.class.keys
		# @attributes = Hash[*self.class.keys.map{|x|[x,nil]}.flatten]
		@attributes = Hash[self.class.keys.each_slice(1).to_a]
	end

	def self.attribute_method?(key)
		self.keys.include?(key)
	end

	def self.keys
		%w(name column data_type rule data is_required hint placeholder)
	end


end