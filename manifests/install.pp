# Class jenkins::install
#
class jenkins::install {

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

  package { 'java-1.6.0-openjdk':
    ensure => 'latest'
  }

  package { 'jenkins':
    ensure  => 'latest',
    require => Package['java-1.6.0-openjdk']
  }

}
