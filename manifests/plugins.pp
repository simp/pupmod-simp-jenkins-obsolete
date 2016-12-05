# == Class: jenkins::plugins
#
# Configure Jenkins' plugins
#
# This class ensures that all necessary plugins for adequate testing
# of the system are installed and ready to use when hudson is installed.
#
# By default, the /srv/rsync/jenkins_plugins directory on the puppet master
# be rsynced with the JENKINS_HOME/plugins directory.
# See rsync::server::section::jenkins_plugins in the simp module
# if you need to edit this.
#
# You can set jenkins::rsync_plugins to false in hiera
# if you want to use the Jenkins plugin update mechanism, or manually download
# and place updated plugin files in the rsync directory on the puppet master
# to enforce it in puppet.
#
# See https://wiki.jenkins-ci.org/display/JENKINS/Plugins for more information.
#
#
# == Authors
#
# * Trevor Vaughan <tvaughan@onyxpoint.com>
#
class jenkins::plugins (
  $rsync_source  = "jenkins_plugins_${::environment}/",
  $rsync_server  = hiera('rsync::server'),
  $rsync_timeout = hiera('rsync::timeout')
){
  include '::rsync'

  file { '/var/lib/jenkins/plugins':
    ensure => 'directory',
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0750'
  }

  rsync { 'jenkins':
    server  => $rsync_server,
    timeout => $rsync_timeout,
    source  => $rsync_source,
    target  => '/var/lib/jenkins/plugins',
    notify  => Service['jenkins']
  }
}
