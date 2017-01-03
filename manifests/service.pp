# Manage the jenkins service
#
class jenkins::service {
  assert_private()

  service { 'jenkins':
    ensure     => 'running',
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
  }

}
