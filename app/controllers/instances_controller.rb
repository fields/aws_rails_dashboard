require 'graphviz'
require 'resolv'
include InstanceUtil

class InstancesController < ApplicationController
  def index
    setup_instance_hashes
    
  end
  
  def make_hosts
    @instances = EC2.describe_instances
    @addrs = {}
    @instances.each{|x| Resolv::DNS.new.each_address(x[:dns_name]) { |addr| @addrs[x[:aws_instance_id]] = addr.to_s }}
  end
  
  def graph_layout
    
    setup_instance_hashes
    g = GraphViz::new( "structs", "type" => "graph")
    g[:rankdir] = "LR"
    g[:pack] = 10
    @instances.each{|instance|
      g.add_node(instance[:aws_instance_id], :shape => "box3d").label = "#{Label.find_by_aws_id(instance[:aws_instance_id]).label rescue ""} (#{instance[:aws_instance_id]})
#{instance[:private_dns_name]}
#{instance[:dns_name]}"
      @volume_ids[instance[:aws_instance_id]].each{|volume_id|
        g.add_node(volume_id, :shape => "ellipse", :style => "filled", :fillcolor => "grey").label = "#{@volumes[volume_id][:aws_device]}
(#{volume_id})
#{@volumes[volume_id][:aws_size]}"
        g.add_edge(instance[:aws_instance_id], volume_id)
        @snapshots[volume_id].each{|snapshot|
          g.add_node(snapshot[:aws_id], :shape => "component").label = "#{snapshot[:aws_id]}
#{snapshot[:aws_started_at]}"
          g.add_edge(volume_id, snapshot[:aws_id])
        }
      }
    }
    # send data
    # g.output (:png => '/Users/fields/Desktop/graph.png')
    output = redirect { g.output(:output => "png") }
    send_data output, :filename => 'aws_graph.png', :type => 'image/png', :disposition => 'inline'
    
  end
  


  def snap_instance
    make_snapshot_of_all_volumes(params[:id])
    redirect_to '/instances' and return
  end
  
  def prune_snapshots
    delete_old_snapshots(params[:id], 2)
    redirect_to '/instances' and return
  end
  
  def destroy_snapshot
    result = delete_snapshot(params[:id])
    redirect_to '/instances' and return
  end

  private


  def setup_instance_hashes
    @instances = EC2.describe_instances
    @all_snapshots = EC2.describe_snapshots
    @all_volumes = EC2.describe_volumes
    @volume_ids = {}
    @volumes = {}
    @snapshots = {}
    @instances.each{|instance|
      @volume_ids[instance[:aws_instance_id]] = @all_volumes.select{|x| x[:aws_attachment_status] == "attached" and x[:aws_instance_id] == instance[:aws_instance_id]}.collect{|x| x[:aws_id]}
      @volume_ids[instance[:aws_instance_id]].each{|volume_id|
        @volumes[volume_id] = @all_volumes.select{|x| x[:aws_id] == volume_id}.first
        @snapshots[volume_id] = @all_snapshots.select{|x| x[:aws_volume_id] == volume_id}        
      } 
    }
    
  end

  def redirect
    orig_defout = $defout
    $defout = StringIO.new
    yield
    $defout.string
  ensure
    $defout = orig_defout
  end

end
