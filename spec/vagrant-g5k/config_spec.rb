require "vagrant-g5k/config"
require 'rspec/its'

describe VagrantPlugins::G5K::Config do
  let(:instance) {described_class.new}
  
  before :each do
    ENV["USER"] = "user"
  end


  describe "defaults" do
    its("project_id"){should == nil}
    its("walltime"){should == "01:00:00"}
    its("username"){should == "user"}
  end

end

