require_relative "../config/environment.rb"
require 'active_support/inflector'

require "pry"

class InteractiveRecord

    def self.table_name
      self.to_s.downcase.pluralize
    end

    def self.column_names
      DB[:conn].results_as_hash = true

      sql = "PRAGMA table_info('#{table_name}')"
      hash = DB[:conn].execute(sql)
      columns = []
      hash.each{|column| columns << column["name"]}
      columns.compact

    end

    def initialize(hash = {}) #when initializing interactive record, default argument must be set to empty hash
      hash.each{|key, value| self.send("#{key}=",value)}
    end

    def table_name_for_insert
      self.class.table_name
    end

    def col_names_for_insert
      self.class.column_names.delete_if{|col| col == "id"}.join(", ")
    end

    def values_for_insert
      values = []
      self.class.column_names.each do |col|
        values << "'#{send(col)}'" unless send(col).nil?
        #we're calling the attr_reader with the send method. e.g. send("name") = self.name. which then returns the value of self.name
      end
      values.join(", ")
    end

    def save
      sql = <<-SQL
        INSERT INTO #{table_name_for_insert} (#{col_names_for_insert})
        VALUES (#{values_for_insert})
      SQL

      DB[:conn].execute(sql)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]

    end

    def self.find_by_name(student_name)
      sql = <<-SQL
        SELECT * FROM #{self.table_name}
        WHERE name = '#{student_name}'
      SQL

      DB[:conn].execute(sql)
    end

    def self.find_by(hash)
      sql = <<-SQL
        SELECT * FROM #{self.table_name}
        WHERE #{hash.keys[0].to_s} = '#{hash.values[0]}'
      SQL

      DB[:conn].execute(sql)
    end


  end
