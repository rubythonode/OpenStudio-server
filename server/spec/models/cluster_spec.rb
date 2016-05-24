require 'rails_helper'

RSpec.describe AnalysisLibrary::R::Cluster, type: :model do
  before :all do
    ComputeNode.delete_all
    FactoryGirl.create(:compute_node)

    # get an analysis (which should be loaded from factory girl)
    @analysis = Analysis.first
    @analysis.run_flag = true
    @analysis.save!

    # create an instance for R
    @r = AnalysisLibrary::Core.initialize_rserve(APP_CONFIG['rserve_hostname'],
                                                 APP_CONFIG['rserve_port'])
  end

  context 'create local cluster' do
    it 'should create an R session' do
      @r.should_not be_nil
    end

    it 'should configure the cluster with an analysis run_flag' do
      @analysis.id.should_not be_nil

      cluster_class = AnalysisLibrary::R::Cluster.new(@r, @analysis.id)
      cluster_class.should_not be_nil

      # get the master cluster IP address
      master_ip = ComputeNode.where(node_type: 'server').first.ip_address
      master_ip.should eq('localhost')

      cf = cluster_class.configure(master_ip)
      cf.should eq(true)
    end

    it 'should start snow cluster' do
      cluster_class = AnalysisLibrary::R::Cluster.new(@r, @analysis.id)
      cluster_class.should_not be_nil

      # get the master cluster IP address
      master_ip = ComputeNode.where(node_type: 'server').first.ip_address
      master_ip.should eq('localhost')

      ip_addresses = ComputeNode.worker_ips
      ip_addresses[:worker_ips].size.should eq(2)

      cf = cluster_class.start(ip_addresses)
      cf.should eq(true)

      cf = cluster_class.stop
      cf.should eq(true)
    end
  end
end