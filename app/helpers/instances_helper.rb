module InstancesHelper
  def label_for(aws_id)
    Label.find_by_aws_id(aws_id).label rescue ""
  end
end
