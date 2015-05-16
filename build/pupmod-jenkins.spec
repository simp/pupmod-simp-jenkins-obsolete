Summary: Jenkins Puppet Module
Name: pupmod-jenkins
Version: 4.1.0
Release: 6
License: Apache License, Version 2.0
Group: Applications/System
Source: %{name}-%{version}-%{release}.tar.gz
Buildroot: %{_tmppath}/%{name}-%{version}-%{release}-buildroot
Requires: pupmod-iptables >= 4.1.0
Requires: pupmod-apache >= 4.1.0
Requires: puppet >= 3.3.0
Buildarch: noarch
Requires: simp-bootstrap >= 4.2.0
Obsoletes: pupmod-jenkins-test

Prefix: /etc/puppet/environments/simp/modules

%description
A puppet module to help you configure the Jenkins continuous integration
system.

This module has the capability to set you up with a reasonably secure, apache
fronted instance with either an internal account (you should change the
password, it's in the conf.pp manifest) or an LDAP backend.

Please read the documentation in the module.

%prep
%setup -q

%build

%install
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/jenkins

dirs='files lib manifests templates'
for dir in $dirs; do
  test -d $dir && cp -r $dir %{buildroot}/%{prefix}/jenkins
done

mkdir -p %{buildroot}/usr/share/simp/tests/modules/jenkins

%clean
[ "%{buildroot}" != "/" ] && rm -rf %{buildroot}

mkdir -p %{buildroot}/%{prefix}/jenkins

%files
%defattr(0640,root,puppet,0750)
%{prefix}/jenkins

%post
#!/bin/sh

if [ -d %{prefix}/jenkins/plugins ]; then
  /bin/mv %{prefix}/jenkins/plugins %{prefix}/jenkins/plugins.bak
fi

%postun
# Post uninstall stuff

%changelog
* Thu Feb 19 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-6
- Migrated to the new 'simp' environment.

* Fri Jan 16 2015 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-5
- Changed puppet-server requirement to puppet

* Thu Dec 04 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-4
- Updated to properly handle the SSL protocols in Apache. We now add a
  + if one is warranted and just keep the entry if it starts with a +
  a minus or is 'all'.

* Fri Oct 17 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-3
- CVE-2014-3566: Updated protocols to mitigate POODLE.

* Mon Sep 01 2014 Trevor Vaughan <tvaughan@onyxpoint.com> - 4.1.0-2
- Updated to support the new LDAP options in Hiera properly.
- Support using all LDAP servers in failover mode.

* Fri May 16 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-1
- Updated apache manifest to convert SSL cipher suite into an array and
  updated the corresponding apache template.

* Tue May 13 2014 Steven Sylvester <ssylvester@keywcorp.com> - 4.1.0-1
- Changed log file permissions and ownership to ensure web service can run properly.

* Mon Mar 10 2014 Nick Markowski <nmarkowski@keywcorp.com> - 4.1.0-0
- Changed top scope variable refs to hiera lookups.

* Sat Mar 01 2014 Kendall Moore <kmoore@keywcorp.com> - 4.1.0-0
- Cleaned up manifests to pass all lint tests.
- Added rspec tests for test coverage.

* Thu Feb 13 2014 Kendall Moore <kmoore@keywcorp.com> - 2.0.2-12
- Converted all boolean strings to native booleans.

* Mon Oct 07 2013 Kendall Moore <kmoore@keywcorp.com> - 2.0.2-11
- Updated all erb templates to properly scope variables.

* Wed Sep 25 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.2-10
- Removed hard coded simp.dev attribute in the LDAP configuration.
- Added the ability to easily disable rsync'd plugins.

* Mon Aug 05 2013 Trevor Vaughan <tvaughan@onyxpoint.com> - 2.0.2-9
- Moved the default temp directory that Jenkins uses since it conflicts with
  the security settings for /tmp.

* Fri Jul 26 2013 Adam Yohrling <adam.yohrling@onyxpoint.com> - 2.0.2-8
- Added support for setting the heap size and perm size for Jenkins.

* Mon Feb 25 2013 Maintenance
2.0.2-7
- Added a call to $::rsync_timeout to the rsync call since it is now required.
- Added +ExportCertData to SSLOptions.

* Thu Jun 07 2012 Maintenance
2.0.2-6
- Ensure that Arrays in templates are flattened.
- Call facts as instance variables.
- Moved mit-tests to /usr/share/simp...
- Updated pp files to better meet Puppet's recommended style guide.

* Mon Mar 12 2012 Maintenance
2.0.2-1
- Updated cucumber tests.
- Added a subscribe on /etc/pki/cacerts to the keystore building exec
  so that it would rebuild when the keys are updated.
- Reformatted to meet the Puppet Labs coding guide.
- Update how plugins are handeled through puppet.
- Improved test stubs.

* Fri Jan 13 2012 Maintenance
2.0.1-2
- Updates to the Jenkins tests.

* Mon Dec 26 2011 Maintenance
2.0.1-1
- Updated the spec file to not require a separate file list.

* Tue Nov 08 2011 Maintenance
2.0.1-0
- Added the first cut at cucumber tests.
- Now pick up the passed header address when rewriting the header.
- The ending slash on jenkins is now optional

* Mon Oct 10 2011 Maintenance
2.0.0-1
- Modified all multi-line exec statements to act as defined on a single line to
  address bugs in puppet 2.7.5

* Sat Jun 18 2011 Maintenance
2.0.0-0
- Initial module offering.
