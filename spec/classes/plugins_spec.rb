require 'spec_helper'

describe 'jenkins::plugins' do

  it { should create_class('jenkins::plugins') }
  it { should contain_class('rsync') }
  it { should create_file('/var/lib/jenkins/plugins').with_ensure('directory') }
end
