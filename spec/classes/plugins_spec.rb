require 'spec_helper'

describe 'jenkins::plugins' do

  it { is_expected.to create_class('jenkins::plugins') }
  it { is_expected.to contain_class('rsync') }
  it { is_expected.to create_file('/var/lib/jenkins/plugins').with_ensure('directory') }
end
