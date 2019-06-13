require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord
  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "pragma table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    table_info.map {|row| row["name"]}.compact # returns => ["id", "name", "grade"]
  end

  def initialize(options={})
    options.each {|property, value| self.send("#{property}=", value)}
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def table_name_for_insert
    self.class.table_name
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ") #returns  ["'Sam'", "'11'"]
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ") #returns => "name, grade"
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = ?"
    DB[:conn].execute(sql, name)
  end

  def self.find_by(attribute)
    value = attribute.values[0]
    value_type = value.class.is_a?(Integer) ? value : "'#{value}'"
    sql = "SELECT * FROM #{self.table_name} WHERE #{attribute.keys[0]} = #{value_type}"
    DB[:conn].execute(sql)
  end

end
