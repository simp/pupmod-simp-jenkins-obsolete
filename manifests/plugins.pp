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
# @param rsync_source
# @param rsync_server
# @param rsync_timeout
#
# @author Trevor Vaughan <tvaughan@onyxpoint.com>
#
class jenkins::plugins (
  String      $rsync_source  = "jenkins_plugins_${::environment}/",
  Simplib::IP $rsync_server  = simplib::lookup('simp_options::rsync::server', { 'default_value' => '127.0.0.1'}),
  Integer     $rsync_timeout = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 })
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
