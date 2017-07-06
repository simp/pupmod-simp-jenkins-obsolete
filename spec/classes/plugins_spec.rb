require 'spec_helper'

describe 'jenkins::plugins' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let(:environment) {'production'}

        it { is_expected.to create_class('jenkins::plugins') }
        it { is_expected.to contain_class('rsync') }
        it { is_expected.to contain_rsync('jenkins').with({
          :source => 'jenkins_plugins_production/'
          })
        }
        it { is_expected.to create_file('/var/lib/jenkins/plugins').with_ensure('directory') }
      end
    end
  end
end
