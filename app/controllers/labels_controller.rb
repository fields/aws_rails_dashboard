class LabelsController < ApplicationController
  layout 'default_layout'
  active_scaffold :labels do |config|
     config.actions = [:list, :create, :delete, :update, :search]
     config.label = "Labels"
     config.columns = [:aws_id, :label, :aws_source_id, :autosnap, :before_snapshot_code, :after_snapshot_code ]
     config.columns[:aws_id].label = "AWS ID"
     config.columns[:autosnap].label = "Snapshot Automatically"
     config.columns[:autosnap].form_ui = :checkbox
     config.columns[:aws_source_id].label = "AWS Source ID"
   end
end
