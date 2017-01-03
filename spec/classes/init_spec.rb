require 'spec_helper'

shared_examples_for "common config" do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('jenkins') }
          it { is_expected.to create_class('jenkins::install')}
          it { is_expected.to create_class('jenkins::service')}
          it { is_expected.to contain_class('jenkins::plugins') }
          it { is_expected.to create_file('/etc/jenkins')}
          it { is_expected.to create_file('/etc/jenkins/pki')}
          it { is_expected.to create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
          it { is_expected.to create_file('/var/log/jenkins/jenkins.log').with({
            :owner    => 'jenkins',
            :group    => 'jenkins',
            :mode     => '0640'
            })
          }
end

describe 'jenkins' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'with default parameters' do
          it_should_behave_like "common config"
          it { is_expected.to_not contain_class('pki') }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_secure_jenkins')}
        end

        context 'with pki = simp and firewall = true and ldap = true' do
          let(:params) {{:pki => 'simp', :firewall => true, :ldap => true}}
          it_should_behave_like "common config"
          it { is_expected.to contain_class('pki')}
          it { is_expected.to create_pki__copy('/etc/jenkins')}
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_secure_jenkins')}
          it { is_expected.to create_simp_apache__add_site('jenkins').with_content(/.*SSLCipherSuite DEFAULT:!MEDIUM\n\n  SSLCertificateFile \/etc\/jenkins\/pki\/public\/foo.example.com.pub\n  SSLCertificateKeyFile \/etc\/jenkins\/pki\/private\/foo.example.com.pem\n  SSLCACertificatePath \/etc\/jenkins\/pki\/cacerts\n\n.* /
          )}
        end
      end
    end
  end
end
