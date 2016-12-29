# Class jenkins::service
#
class jenkins::service {

  service { 'jenkins':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }

}
