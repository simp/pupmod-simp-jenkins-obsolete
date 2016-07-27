require 'spec_helper'

describe 'jenkins' do

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
        # Check hieradata/default.yaml to see which variables have been set.
          it { is_expected.to compile.with_all_deps }
          it { should create_class('jenkins') }
          it { should contain_class('jenkins::plugins') }
          it { should create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
          it { should create_file('/var/log/jenkins/jenkins.log').with({
            :owner    => 'jenkins',
            :group    => 'jenkins',
            :mode     => '0640'
            })
          }

        end
      end
    end
  end
end
