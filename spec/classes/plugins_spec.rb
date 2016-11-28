require 'spec_helper'

describe 'jenkins::plugins' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        it { should create_class('jenkins::plugins') }
        it { should contain_class('rsync') }
        it { should create_file('/var/lib/jenkins/plugins').with_ensure('directory') }
      end
    end
  end
end
