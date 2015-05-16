require 'spec_helper'

describe 'jenkins' do

  base_facts = {
    "RHEL 6" => {
      :apache_version => '2.2',
      :fqdn => 'spec.test',
      :grub_version => '0.97',
      :hardwaremodel => 'x86_64',
      :init_systems => ['sysv','rc','upstart'],
      :interfaces => 'lo,eth0',
      :ipaddress => '1.2.3.4',
      :ipaddress_eth0 => '1.2.3.4',
      :ipaddress_lo => '127.0.0.1',
      :lsbmajdistrelease => '6',
      :operatingsystem => 'RedHat',
      :operatingsystemmajrelease => '6',
      :passenger_root => '/usr/lib/ruby/gems/1.8/gems/passenger',
      :passenger_version => '4',
      :processorcount => 4,
      :selinux_current_mode => 'enabled',
      :trusted => { 'certname' => 'spec.test' },
      :uid_min => '500'
    },
    "RHEL 7" => {
      :apache_version => '2.4',
      :fqdn => 'spec.test',
      :grub_version => '2.02~beta2',
      :hardwaremodel => 'x86_64',
      :init_systems => ['sysv','rc','upstart'],
      :interfaces => 'lo,eth0',
      :ipaddress => '1.2.3.4',
      :ipaddress_eth0 => '1.2.3.4',
      :ipaddress_lo => '127.0.0.1',
      :lsbmajdistrelease => '7',
      :operatingsystem => 'RedHat',
      :operatingsystemmajrelease => '7',
      :passenger_root => '/usr/lib/ruby/gems/1.8/gems/passenger',
      :processorcount => 4,
      :passenger_version => '4',
      :selinux_current_mode => 'enabled',
      :trusted => { 'certname' => 'spec.test' },
      :uid_min => '500'
    }
  }

  shared_examples_for "a fact set" do
    # Check hieradata/default.yaml to see which variables have been set.
    it { should create_class('jenkins') }
    it { should contain_class('jenkins::plugins') }
    it { should create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
    it { should create_file('/var/log/jenkins/jenkins.log').with({
        :owner    => 'jenkins',
        :group    => 'jenkins',
        :mode     => '0640'
       })
    }

    context 'base' do
      it { should create_class('jenkins') }
    end
  end

  describe "RHEL 6" do
    it_behaves_like "a fact set"
    let(:facts) {base_facts['RHEL 6']}
  end

  describe "RHEL 7" do
    it_behaves_like "a fact set"
    let(:facts) {base_facts['RHEL 7']}
  end
end
