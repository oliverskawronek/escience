class ChangeDefaultForLanguage < ActiveRecord::Migration
  def self.up
    change_table :users do |t| 
      t.change :language, :default => "de"
    end
  end

  def self.down
    change_table :users do |t| 
      t.change :language, :default => ""
    end
  end
end
