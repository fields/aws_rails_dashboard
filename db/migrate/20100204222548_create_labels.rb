class CreateLabels < ActiveRecord::Migration
  def self.up
    create_table :labels do |t|
      t.column :aws_id, :string
      t.column :label, :string
      t.column :aws_source_id, :string
      t.timestamps
    end
  end

  def self.down
    drop_table :labels
  end
end
