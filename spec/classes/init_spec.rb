require 'spec_helper'

shared_examples_for "common config" do
  it { is_expected.to compile.with_all_deps }
  it { is_expected.to create_class('jenkins') }
  it { is_expected.to create_class('jenkins::install')}
  it { is_expected.to create_class('jenkins::service')}
  it { is_expected.to contain_class('jenkins::plugins') }
  it { is_expected.to create_file('/etc/jenkins')}
  it { is_expected.to contain_exec('build_jenkins_keystore') }
  it { is_expected.to create_file('/var/lib/jenkins/cacerts.jks').with_ensure('file') }
  it { is_expected.to create_file('/var/lib/jenkins/users').with_ensure('directory') }
  it { is_expected.to create_file('/var/lib/jenkins/users/dont_panic').with_ensure('directory') }
  it { is_expected.to create_file('/var/lib/jenkins/users/dont_panic/config.xml').with_content(<<EOM
<?xml version='1.0' encoding='UTF-8'?>
<user>
  <fullName>Don&apos;t Panic</fullName>
  <properties>
    <hudson.model.MyViewsProperty>
      <primaryViewName>All</primaryViewName>
      <views>
        <hudson.model.AllView>
          <owner class="hudson.model.MyViewsProperty" reference="../../.."/>
          <name>All</name>
          <filterExecutors>false</filterExecutors>
          <filterQueue>false</filterQueue>
          <properties class="hudson.model.View$PropertyList"/>
        </hudson.model.AllView>
      </views>
    </hudson.model.MyViewsProperty>
    <hudson.security.HudsonPrivateSecurityRealm_-Details>
      <passwordHash>AzWMRl:cea6f1d3e7065b28c8b1233a26df87f5eebbe8f6e9d4617b6367ae635e80ec22</passwordHash>
    </hudson.security.HudsonPrivateSecurityRealm_-Details>
    <hudson.tasks.Mailer_-UserProperty>
      <emailAddress>dont_panic@example.com</emailAddress>
    </hudson.tasks.Mailer_-UserProperty>
  </properties>
</user>
EOM
  ) }
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
          it { is_expected.to create_file('/etc/jenkins/pki')}
        end

        context 'with pki = simp' do
          let(:params) {{ :pki => 'simp' }}
          it_should_behave_like "common config"
          it { is_expected.to contain_class('pki')}
          it { is_expected.to create_pki__copy('jenkins')}
        end

        context 'with pki = true' do
          let(:params) {{ :pki => true }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_class('pki')}
          it { is_expected.to create_pki__copy('jenkins')}
        end

        context 'with rsync_plugins = false' do
          let(:params) {{ :rsync_plugins => false }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to_not contain_class('jenkins::plugins') }
        end

        context 'with setup_apache = true, jenkins_port = 443' do
          let(:params) {{ :setup_apache => true, :jenkins_port => 443 }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_simp_apache__site('jenkins').with_content(<<EOM
<Proxy http://localhost:8081/jenkins*>
  Order deny,allow
  Allow from all
</Proxy>

ProxyRequests off
ProxyPreserveHost on
ProxyPass /jenkins/ http://localhost:8081/jenkins/
ProxyPass /jenkins http://localhost:8081/jenkins/

<Location /jenkins/>

  SSLOptions +StdEnvVars +ExportCertData
  SSLVerifyClient optional
  SSLVerifyDepth  10

  SSLProtocol +TLSv1 +TLSv1.1 +TLSv1.2
  SSLCipherSuite DEFAULT:!MEDIUM

  RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
  RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

  ProxyPassReverse /
  Order deny,allow
  Allow from all
  Header edit location ^http://(.*):443/jenkins/? https://$1:443/jenkins/
  Header edit location ^http://(.*)/jenkins/? https://$1/jenkins/

</Location>
EOM
          ) }
          it { is_expected.to create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
        end

        context 'with setup_apache = true, jenkins_port = 8080' do
          let(:params) {{ :setup_apache => true, :jenkins_port => 8080 }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_simp_apache__site('jenkins').with_content(<<EOM
<Proxy http://localhost:8081/jenkins*>
  Order deny,allow
  Allow from all
</Proxy>

Listen 8080
<VirtualHost _default_:8080>

  ProxyPreserveHost on
  ProxyRequests off
  Proxypass /jenkins/ http://localhost:8081/jenkins/
  Proxypass /jenkins http://localhost:8081/jenkins/
  <Location /jenkins/>
    ProxyPassReverse /
    Order deny,allow
    Allow from all
  </Location>
  Header edit location ^http://(.*):8080/jenkins/? https://$1:8080/jenkins/

  SSLEngine on

  SSLProtocol +TLSv1 +TLSv1.1 +TLSv1.2
  SSLCipherSuite DEFAULT:!MEDIUM

  SSLCertificateFile /etc/jenkins/pki/public/foo.example.com.pub
  SSLCertificateKeyFile /etc/jenkins/pki/private/foo.example.com.pem
  SSLCACertificatePath /etc/jenkins/pki/cacerts

  SSLOptions +StdEnvVars +ExportCertData
  SSLVerifyClient optional
  SSLVerifyDepth  10

  RequestHeader set X-Client-DN %{SSL_CLIENT_S_DN}e
  RequestHeader set X-Client-Verify %{SSL_CLIENT_VERIFY}e

  ErrorLog syslog:local6

</VirtualHost>
EOM
          ) }
          it { is_expected.to create_file('/etc/httpd/conf.d/jenkins.conf').with_content(/localhost\:8081/) }
        end

        context 'with setup_conf = true, but ldap, firewall, and enable_external_yumrepo false' do
          let(:params) {{ :setup_conf => true, :ldap => false, :firewall => false }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/etc/sysconfig/jenkins').with_content(<<EOM
JENKINS_HOME="/var/lib/jenkins"
JENKINS_JAVA_CMD=""
JENKINS_USER="jenkins"
JENKINS_JAVA_OPTIONS="-Djava.io.tmpdir=/var/lib/jenkins/tmp -Djava.awt.headless=true -Djavax.net.ssl.trustStore=/var/lib/jenkins/cacerts.jks -Xmx1024m -XX:PermSize=32m -XX:MaxPermSize=256m"
JENKINS_PORT="8081"
JENKINS_DEBUG_LEVEL="5"
JENKINS_ENABLE_ACCESS_LOG="no"
JENKINS_HANDLER_MAX="100"
JENKINS_HANDLER_IDLE="20"
JENKINS_ARGS="--httpListenAddress=127.0.0.1 --prefix=/jenkins"
EOM
          ) }
          it { is_expected.to create_file('/var/lib/jenkins').with_ensure('directory') }
          it { is_expected.to create_file('/var/lib/jenkins/tmp').with_ensure('directory') }
          it { is_expected.to create_file('/var/lib/jenkins/config.xml').with_content(<<EOM
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <version>1.411</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.ProjectMatrixAuthorizationStrategy">
    <permission>hudson.model.Hudson.Administer:dont_panic</permission>
    <permission>hudson.model.Hudson.Read:anonymous</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
    <disableSignup>true</disableSignup>
  </securityRealm>
  <markupFormatter class="hudson.markup.RawHtmlMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
    <PROXY__HEADER>X-Forwarded-For</PROXY__HEADER>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <disabledAdministrativeMonitors>
    <string>hudson.diagnosis.ReverseProxySetupMonitor</string>
  </disabledAdministrativeMonitors>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
EOM
          ) }
          it { is_expected.to_not create_iptables__listen__tcp_stateful('allow_secure_jenkins')}
          it { is_expected.to create_yumrepo('jenkins').with_enabled(0) }
        end

        context 'with setup_conf = true, ldap = false, allow_anonymous_read = false, allow_signup = true' do
          let(:params) {{ :setup_conf => true, :ldap => false, :allow_anonymous_read => false, :allow_signup => true }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/lib/jenkins/config.xml').with_content(<<EOM
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <version>1.411</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.ProjectMatrixAuthorizationStrategy">
    <permission>hudson.model.Hudson.Administer:dont_panic</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.HudsonPrivateSecurityRealm">
  </securityRealm>
  <markupFormatter class="hudson.markup.RawHtmlMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
    <PROXY__HEADER>X-Forwarded-For</PROXY__HEADER>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <disabledAdministrativeMonitors>
    <string>hudson.diagnosis.ReverseProxySetupMonitor</string>
  </disabledAdministrativeMonitors>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
EOM
          ) }
        end

        context 'with setup_conf, ldap, firewall, and enable_external_yumrepo true' do
          let(:params) {{ :setup_conf => true, :ldap => true, :default_ldap_admin => 'jinkles',
            :firewall => true, :enable_external_yumrepo => true
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/lib/jenkins/config.xml').with_content(<<EOM
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <version>1.411</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.ProjectMatrixAuthorizationStrategy">
    <permission>hudson.model.Hudson.Administer:jinkles</permission>
    <permission>hudson.model.Hudson.Read:anonymous</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.LDAPSecurityRealm">
    <server>ldaps://test.example.domain</server>
    <rootDN>dc=example,dc=domain</rootDN>
    <inhibitInferRootDN>false</inhibitInferRootDN>
    <userSearchBase>ou=People</userSearchBase>
    <userSearch>uid={0}</userSearch>
    <groupSearchBase>ou=Group</groupSearchBase>
    <managerDN>cn=hostAuth,ou=Hosts,dc=example,dc=domain</managerDN>
    <managerPassword>e1NTSEF9bGtqZGZhZ2xramRmc2w7a2ZkbGtzZ3NkZmdkZmdnZmQ=
</managerPassword>
  </securityRealm>
  <markupFormatter class="hudson.markup.RawHtmlMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
    <PROXY__HEADER>X-Forwarded-For</PROXY__HEADER>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <disabledAdministrativeMonitors>
    <string>hudson.diagnosis.ReverseProxySetupMonitor</string>
  </disabledAdministrativeMonitors>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
EOM
          ) }
          it { is_expected.to create_iptables__listen__tcp_stateful('allow_secure_jenkins').with(
            :order        => 11,
            :trusted_nets => ['1.2.3.4/32'],
            :dports       =>  8080
          )}
          it { is_expected.to create_yumrepo('jenkins').with_enabled(1) }
        end

        context "with setup_conf = true, ldap = true, allow_anonymous_read = false, ldap_bind_dn = ''" do
          let(:params) {{ :setup_conf => true, :ldap => true, :default_ldap_admin => 'jinkles',
            :allow_anonymous_read => false, :ldap_bind_dn => ''
          }}
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_file('/var/lib/jenkins/config.xml').with_content(<<EOM
<?xml version='1.0' encoding='UTF-8'?>
<hudson>
  <version>1.411</version>
  <numExecutors>2</numExecutors>
  <mode>NORMAL</mode>
  <useSecurity>true</useSecurity>
  <authorizationStrategy class="hudson.security.ProjectMatrixAuthorizationStrategy">
    <permission>hudson.model.Hudson.Administer:jinkles</permission>
  </authorizationStrategy>
  <securityRealm class="hudson.security.LDAPSecurityRealm">
    <server>ldaps://test.example.domain</server>
    <rootDN>dc=example,dc=domain</rootDN>
    <inhibitInferRootDN>false</inhibitInferRootDN>
    <userSearchBase>ou=People</userSearchBase>
    <userSearch>uid={0}</userSearch>
    <groupSearchBase>ou=Group</groupSearchBase>
  </securityRealm>
  <markupFormatter class="hudson.markup.RawHtmlMarkupFormatter"/>
  <jdks/>
  <viewsTabBar class="hudson.views.DefaultViewsTabBar"/>
  <myViewsTabBar class="hudson.views.DefaultMyViewsTabBar"/>
  <clouds/>
  <slaves/>
  <quietPeriod>5</quietPeriod>
  <scmCheckoutRetryCount>0</scmCheckoutRetryCount>
  <views>
    <hudson.model.AllView>
      <owner class="hudson" reference="../../.."/>
      <name>All</name>
      <filterExecutors>false</filterExecutors>
      <filterQueue>false</filterQueue>
      <properties class="hudson.model.View$PropertyList"/>
    </hudson.model.AllView>
  </views>
  <primaryView>All</primaryView>
  <slaveAgentPort>0</slaveAgentPort>
  <label></label>
  <crumbIssuer class="hudson.security.csrf.DefaultCrumbIssuer">
    <excludeClientIPFromCrumb>true</excludeClientIPFromCrumb>
    <PROXY__HEADER>X-Forwarded-For</PROXY__HEADER>
  </crumbIssuer>
  <nodeProperties/>
  <globalNodeProperties/>
  <disabledAdministrativeMonitors>
    <string>hudson.diagnosis.ReverseProxySetupMonitor</string>
  </disabledAdministrativeMonitors>
  <noUsageStatistics>true</noUsageStatistics>
</hudson>
EOM
          ) }
        end

        context 'with ldap = true but default_ldap_admin not set' do
          let(:params) {{ :ldap => true }}
          it { expect { is_expected.to compile }.to raise_error(/If \$ldap is true, you must provide \$default_ldap_admin/) }
        end
      end
    end
  end
end
