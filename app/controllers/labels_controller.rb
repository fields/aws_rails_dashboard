class LabelsController < ApplicationController
  layout 'default_layout'
  active_scaffold :labels do |config|
     config.actions = [:list, :create, :delete, :update]
     config.label = "Labels"
     config.columns = [:aws_id, :label, :aws_source_id, :autosnap ]
     config.columns[:aws_id].label = "AWS ID"
     config.columns[:autosnap].label = "Snapshot Automatically"
     config.columns[:autosnap].form_ui = :checkbox
     config.columns[:aws_source_id].label = "AWS Source ID"
   end
end
