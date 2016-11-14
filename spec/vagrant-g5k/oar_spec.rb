require "vagrant-g5k/oar"
require 'rspec/its'
require 'rspec/mocks'

describe VagrantPlugins::G5K::Oar do
  describe "_build_oar_cmd" do
    it "builds the wanted oar string" do
      oar = VagrantPlugins::G5K::Oar.new(nil)
      cmd = oar._build_oar_cmd([
        "a",
        "b"
      ])
      expect(cmd).to eq "a b"
    end
  end

  describe "submit_job" do
    it "submit job without error" do
      driver = double("driver")
      expect(driver).to receive(:exec)
                    .with("oarsub --json -t deploy 'sleep 1' | grep \"job_id\"| cut -d':' -f2")
                   .and_return("1")
      oar = VagrantPlugins::G5K::Oar.new(driver)
      job_id = oar.submit_job("sleep 1", [
        "-t deploy"
      ])
      expect(job_id).to eq 1
    end
  end

  describe "delete_job" do
    it "delete job without error" do
      driver = double("driver")
      expect(driver).to receive(:exec).with("oardel -c -s 12 1")
      oar = VagrantPlugins::G5K::Oar.new(driver)
      oar.delete_job(1, [
        "-c",
        "-s 12"
      ])
    end
  end

  describe "check_job" do
    it "check the job" do
      driver = double("driver")
      expect(driver).to receive(:exec).with("oarstat --json -j 1")
                   .and_return('{"1" : {"name" : "foo"}}')
      oar = VagrantPlugins::G5K::Oar.new(driver)
      job = oar.check_job(1)
      expect(job).to include({"name" => "foo"})
      puts job
    end
  end


end

