require 'spec_helper'

describe 'jenkins' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      base_facts = {
        ###:apache_version => '2.4',
        :fqdn => 'spec.test',
        :grub_version => '2.02~beta2',
        :hardwaremodel => 'x86_64',
        :init_systems => ['sysv','rc','upstart'],
        :interfaces => 'lo,eth0',
        :ipaddress => '1.2.3.4',
        :ipaddress_eth0 => '1.2.3.4',
        :ipaddress_lo => '127.0.0.1',
        :lsbmajdistrelease => '7',
        ##:passenger_root => '/usr/lib/ruby/gems/1.8/gems/passenger',
        :processorcount => 4,
        :passenger_version => '4',
        :selinux_current_mode => 'enabled',
        :trusted => { 'certname' => 'spec.test' },
        :uid_min => '500'
      }
      let(:facts) {facts.merge(base_facts)}

      shared_examples_for "a fact set" do
        # Check hieradata/default.yaml to see which variables have been set.
        it { is_expected.to create_class('jenkins') }
        it { is_expected.to contain_class('jenkins::plugins') }
        it { is_expected.to create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
        it { is_expected.to create_file('/var/log/jenkins/jenkins.log').with({
            :owner    => 'jenkins',
            :group    => 'jenkins',
            :mode     => '0640'
           })
        }

        context 'base' do
          it { is_expected.to create_class('jenkins') }
        end
      end

      describe "a default installation" do
        it_behaves_like "a fact set"
      end
    end
  end
end
