# Manage the installation of jenkins
#
# @param java_package Name of the java package to install
#
class jenkins::install (
  String $java_package = 'java-1.6.0-openjdk'
){

  group { 'jenkins':
    ensure    => 'present',
    allowdupe => false,
    gid       => '419'
  }

  user { 'jenkins':
    ensure     => 'present',
    allowdupe  => false,
    comment    => 'Jenkins',
    gid        => '419',
    uid        => '419',
    membership => 'inclusive',
    shell      => '/sbin/nologin',
    home       => '/var/lib/jenkins',
    before     => Package['jenkins'],
    require    => Group['jenkins']
  }

  package { $java_package:
    ensure => 'latest'
  }

  package { 'jenkins':
    ensure  => 'latest',
    require => Package[$java_package]
  }

}
