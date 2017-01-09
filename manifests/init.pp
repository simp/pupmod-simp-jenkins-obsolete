# Configure Jenkins
#
# This class, and the associated defines, should provide relatively
# comprehensive coverage of the Jenkins features.
#
# See http://jenkins-ci.org/ for more information.
#
# The local Java Keystore password is randomly generated.
#
# Use the command 'simp passgen -u jenkins' on the puppet server, as root to
# show the autogenerated password for the keystore.
#
# If you ever need to generate a new password, simply run 'simp passgen -r
# jenkins' and the next puppet run will generate a new password.
#
# By default Jenkins is started on port 8080 and under the 'jenkins' namespace.
# This means that your access URI will be something like
# http://your.server.fqdn:8080/jenkins/. Don't forget the trailing slash!
#
# To enable Jenkins inside of apache, set jenkins::setup_apache to true in hiera.
#
# == Notes
#
# In order to setup a stock jenkins instance, set the following in hiera:
#   jenkins::setup_apache: true
#   jenkins::setup_conf: true
#
# @param rsync_plugins
# @param setup_apache
# @param setup_conf
# @param jenkins_port
#   The port upon which Apache will listen for connections.
#   Set this to 443 to just run behind the native SSL implementation.
#
# @param jenkins_proxy_port
#   The port upon which Jenkins will listen for proxy connections from Apache.
#
# @param jenkins_tmpdir
#   The temporary directory at which jenkins should point.
#
# @param heap_size
#   The -Xmx setting for the JRE in megabytes
#
# @param perm_size
#   The Permanent Generation initial memory size, in megebytes.
#
# @param max_perm_size
#   The ceiling on the Permanent Generation memory size, in megabytes.
#
# @param jenkins_enable_access_log
#   Whether or not to enable the Jenkins access log.
#
# @param jenkins_handler_max
#   Maximum number of Jenkins worker threads to allow.
#
# @param jenkins_handler_idle
#   Maximum number of idle Jenkins worker threads to allow.
#
# @param trusted_nets
#   An array of networks, in Apache allow/deny compatible notation, that will
#   be allowed to talk to this server.
#
# @param jenkins_keystore
#   The Jenkins keystore location
#
# @param ssl_protocols
#   The allowed SSL protocols (Apache SSLProtocol)
#
# @param openssl_cipher_suite
#   The allowed SSL Ciphers
#
# @param sslverifyclient
# @param sslverifydepth
# @param app_pki_dir
# @param app_pki_external_source
# @param app_pki_ca_dir
# @param app_pki_cert
# @param app_pki_key
#
# @param logfacility
#   It is assumed that you'll want to offload any Apache logs to your log
#   server since they are probably security relevant. However, if this is not
#   the case, simply change the facility here.)
#
# @param enable_external_yumrepo
#   Set this to true to point to the public yum repo for Jenkins.
#
# @param ldap
#   Whether or not to use LDAP as your authentication backend.
#
# @param ldap_uri
#   The URI of the LDAP server.
#
# @param ldap_base_dn
#   The Base DN of the LDAP search space.
#
# @param user_search_base
#   The path down which to search for users
#
# @param group_search_base
#   The path down which to search for groups. This doesn't really work with
#   PosixGroups right now but instead needs a GroupOfNames.
#
# @param ldap_bind_dn
#   The user to use to authenticate to the LDAP server.
#   Set to blank ('') to use anonymous binding.
#
# @param ldap_bind_pw
#   The password to use when binding to the LDAP server.
#
# @param default_ldap_admin
#   The default LDAP administrative user. You MUST specify this
#   or you'll have to hack config.xml later to get into your system.
#   This must be a valid LDAP user!
#
# @param allow_anonymous_read
#   Whether or not to allow anonymous users to read the main dashboard view.
#
# @param allow_signup
#   Allow users to sign up for Jenkins accounts. No effect with $ldap =
#   true
#
# @param firewall
#   Whether or not to include the SIMP iptables class and manage firewall rules.
#   false
#
# @param pki
#   Whether or not to let simp manage pki certs.
#   See the pupmod-simp-pki module for more details.
#
# @app_pki_external_source
#   the location from which the pki certs will be copied from.
#   If using pki = simp leave this the default.
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class jenkins (
  Boolean                       $rsync_plugins             = true,
  Boolean                       $setup_apache              = false,
  Boolean                       $setup_conf                = false,
  Simplib::Port                 $jenkins_port              = 8080,
  Simplib::Port                 $jenkins_proxy_port        = 8081,
  Stdlib::Absolutepath          $jenkins_tmpdir            = '/var/lib/jenkins/tmp',
  Integer                       $heap_size                 = 1024,
  Integer                       $perm_size                 = 32,
  Integer                       $max_perm_size             = 256,
  Enum['yes','no']              $jenkins_enable_access_log = 'no',
  Integer                       $jenkins_handler_max       = 100,
  Integer                       $jenkins_handler_idle      = 20,
  Simplib::Netlist              $trusted_nets              = simplib::lookup('simp_options::trusted_nets', { 'default_value' => ['127.0.0.1', '::1']}),
  Stdlib::Absolutepath          $jenkins_keystore          = '/var/lib/jenkins/cacerts.jks',
  Array[String]                 $ssl_protocols             = ['TLSv1','TLSv1.1','TLSv1.2'],
  Array[String]                 $openssl_cipher_suite      = simplib::lookup('simp_options::openssl::cipher_suites', { 'default_value' => ['DEFAULT', '!MEDIUM']}),
  Jenkins::Sslverifyclient      $sslverifyclient           = 'optional',
  Integer                       $sslverifydepth            = 10,
  Variant[Enum['simp'],Boolean] $pki                       = simplib::lookup('simp_options::pki', { 'default_value' => false}),
  Stdlib::Absolutepath          $app_pki_dir               = '/etc/jenkins',
  Stdlib::Absolutepath          $app_pki_external_source   = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/simp/pki' }),
  Stdlib::Absolutepath          $app_pki_ca_dir            = '/etc/jenkins/pki/cacerts',
  Stdlib::Absolutepath          $app_pki_cert              = "/etc/jenkins/pki/public/${facts['fqdn']}.pub",
  Stdlib::Absolutepath          $app_pki_key               = "/etc/jenkins/pki/private/${facts['fqdn']}.pem",
  String                        $logfacility               = 'local6',
  Boolean                       $enable_external_yumrepo   = false,
  Boolean                       $ldap                      = simplib::lookup('simp_options::ldap', { 'default_value' => false }),
  Array[String]                 $ldap_uri                  = simplib::lookup('simp_options::ldap::uri', { 'default_value' => ["ldap://%{hiera('simp_options::puppet::server')}"]}),
  String                        $ldap_base_dn              = simplib::lookup('simp_options::ldap::base_dn'),
  String                        $user_search_base          = 'ou=People',
  String                        $group_search_base         = 'ou=Group',
  String                        $ldap_bind_dn              = simplib::lookup('simp_options::ldap::bind_dn', { 'default_value' => "cn=hostAuth,ou=Hosts,%{hiera('simp_options::ldap::base_dn')}"}),
  String                        $ldap_bind_pw              = simplib::lookup('simp_options::ldap::bind_pw'),
  Optional[String]              $default_ldap_admin        = undef,
  Boolean                       $allow_anonymous_read      = true,
  Boolean                       $allow_signup              = false,
  Boolean                       $firewall                  = simplib::lookup('simp_options::firewall', { 'default_value' => false})
) {

  if $ldap and !$default_ldap_admin {
    fail('If $ldap is true, you must provide $default_ldap_admin')
  }

  include 'jenkins::install'
  include 'jenkins::service'

  Class['jenkins::install'] ->
  Class['jenkins'] ~>
  Class['jenkins::service']

  file { '/etc/jenkins':
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'jenkins',
  }

  if $pki {
    if $pki == 'simp' { include '::pki' }

    pki::copy { $module_name :
      source => $app_pki_external_source,
      pki    => $pki
    }
  }
  else {
    file { "${app_pki_dir}/pki":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640'
    }
  }

  if $rsync_plugins {
    include 'jenkins::plugins'
  }

  $l_jenkins_pass = inline_template('<%= scope.function_passgen(["jenkins",24]) %>')

  $l_jenkins_keystore = '/var/lib/jenkins/cacerts.jks'

  exec { 'build_jenkins_keystore':
    command     => "/bin/rm ${l_jenkins_keystore}; \
                for file in ${app_pki_ca_dir}/*.pem; do \
                  /usr/bin/keytool -import -keystore ${l_jenkins_keystore} -trustcacerts -noprompt -alias `/bin/basename \$file` -file \$file -storepass ${l_jenkins_pass}; \
                done; \
                chmod 640 ${l_jenkins_keystore}; \
                chown root.jenkins ${l_jenkins_keystore}",
    refreshonly => true,
    require     => [
      Package['java-1.6.0-openjdk'],
      Package['jenkins']
    ],
    notify      => Service['jenkins']
  }

  file { '/var/lib/jenkins/cacerts.jks':
    ensure => 'file',
    owner  => 'root',
    group  => 'jenkins',
    mode   => '0640',
    notify => Exec['build_jenkins_keystore']
  }

  file { '/var/lib/jenkins/users':
    ensure  => 'directory',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    require => Package['jenkins']
  }

  file { '/var/lib/jenkins/users/dont_panic':
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0640'
  }

  file { '/var/lib/jenkins/users/dont_panic/config.xml':
    ensure  => 'file',
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0640',
    content => template('jenkins/dont_panic.xml.erb'),
    notify  => Service['jenkins']
  }

  file { '/var/log/jenkins/jenkins.log' :
    ensure => 'file',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0640'
  }

  $_jenkins_port = $jenkins_port ? {
    443     => template('jenkins/apache_native_ssl.erb'),
    default => template('jenkins/apache.erb')
  }
  if $setup_apache {
    simp_apache::site { 'jenkins':
      content => $_jenkins_port
    }
  }

  if $setup_conf {
    file { '/etc/sysconfig/jenkins':
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('jenkins/sysconfig.erb'),
      notify  => Service['jenkins'],
      require => Package['jenkins']
    }

    file { '/var/lib/jenkins':
      ensure => 'directory',
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0640'
    }

    # If this is not '/tmp'
    if ! ( $jenkins_tmpdir in [ '/tmp', '/var/tmp', '/usr/tmp', '/dev/shm' ] ) {
      file { $jenkins_tmpdir:
        ensure => 'directory',
        owner  => 'jenkins',
        group  => 'jenkins',
        mode   => '0640',
        notify => File['/var/lib/jenkins/config.xml']
      }
    }

    $_config_content = $ldap ? {
      true    => template('jenkins/ldap_config.xml.erb'),
      default => template('jenkins/config.xml.erb')
    }

    file { '/var/lib/jenkins/config.xml':
      ensure  => 'file',
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0640',
      replace => false,
      content => $_config_content,
      require => Package['jenkins'],
      notify  => Service['jenkins']
    }

    if $firewall {
      include 'iptables'

      iptables::listen::tcp_stateful { 'allow_secure_jenkins':
        order        => 11,
        trusted_nets => $trusted_nets,
        dports       => $jenkins_port
      }
    }

    $_jenkins_enabled = $enable_external_yumrepo ? {
      true  => 1,
      false => 0
    }
    yumrepo { 'jenkins':
      baseurl         => 'http://pkg.jenkins-ci.org/redhat/',
      descr           => 'Jenkins Repository',
      enabled         => $_jenkins_enabled,
      gpgcheck        => 1,
      gpgkey          => 'http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key',
      keepalive       => 0,
      metadata_expire => '3600',
      require         => Package['jenkins']
    }
  }
}
