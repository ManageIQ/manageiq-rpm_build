Name:             kafka
Summary:          Apache Kafka is an open-source stream-processing software platform
Version:          3.7.0
Release:          1%{?dist}
License:          Apache (v2)
Group:            Applications
URL:              https://kafka.apache.org
BuildRequires:    java-11-openjdk-devel
BuildRequires:    systemd-rpm-macros
Requires:         java-11-openjdk
Requires(post):   systemd
Requires(postun): systemd
Requires(preun):  systemd
Source0:          http://archive.apache.org/dist/%{name}/%{version}/%{name}-%{version}-src.tgz
Source1:          kafka.service
Source2:          zookeeper.service
Provides:         kafka
BuildRoot:        %{_tmppath}/%{name}-%{version}-root


%global debug_package %{nil}
%define __jar_repack 0
%define kafka_home /opt/kafka
%define kafka_group %{name}
%define kafka_user %{name}


%description
Kafka® is used for building real-time data pipelines and streaming apps. It is horizontally scalable, fault-tolerant, wicked fast, and runs in production in thousands of companies.


%pre
groupadd -fr %{kafka_group}
getent passwd %{kafka_user} >/dev/null || useradd -r -g %{kafka_group} -d %{_sharedstatedir}/kafka -s /sbin/nologin -c "User for kafka services" %{kafka_user}


%prep
%setup -q -n %{name}-%{version}-src


%build
./gradlew jar


%install
mkdir -p %{buildroot}%{kafka_home}
mkdir -p %{buildroot}%{kafka_home}/config/keystore
mkdir -p %{buildroot}%{kafka_home}/libs
mkdir -p %{buildroot}%{_localstatedir}/log/kafka
mkdir -p %{buildroot}%{_sharedstatedir}/kafka
mkdir -p %{buildroot}%{_localstatedir}/log/zookeeper
mkdir -p %{buildroot}%{_sharedstatedir}/zookeeper

rm -rf bin/windows
cp LICENSE %{buildroot}%{kafka_home}
cp NOTICE %{buildroot}%{kafka_home}
cp -r bin %{buildroot}%{kafka_home}
sed "s,log.dirs=.*,log.dirs=%{_sharedstatedir}/kafka," config/server.properties > %{buildroot}%{kafka_home}/config/server.properties
sed "s,dataDir=.*,dataDir=%{_sharedstatedir}/zookeeper," config/zookeeper.properties > %{buildroot}%{kafka_home}/config/zookeeper.properties
cp -r config %{buildroot}%{kafka_home}/config-sample
cp config/log4j.properties %{buildroot}%{kafka_home}/config
cp config/tools-log4j.properties %{buildroot}%{kafka_home}/config
cp -n */build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */build/dependant-libs*/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/dependant-libs*/* %{buildroot}%{kafka_home}/libs

# Install systemd units
install -m755 -d %{buildroot}%{_unitdir}
install -pm644 %SOURCE1 %SOURCE2 %{buildroot}%{_unitdir}/


%files
%defattr(-,root,root)
%{_unitdir}/kafka.service
%{_unitdir}/zookeeper.service
%{kafka_home}
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_sharedstatedir}/kafka
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_localstatedir}/log/kafka
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_sharedstatedir}/zookeeper
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_localstatedir}/log/zookeeper


%post
%systemd_post kafka.service
%systemd_post zookeeper.service


%preun
%systemd_preun kafka.service
%systemd_preun zookeeper.service


%postun
%systemd_postun_with_restart kafka.service
%systemd_postun_with_restart zookeeper.service


%clean
rm -rf %{buildroot}


%changelog
* Wed Feb 28 2024 "Brandon Dunne" <brandondunne@hotmail.com> - 3.7.0-1
- Upgrade to 3.7.0

* Thu Feb 22 2024 "Brandon Dunne" <brandondunne@hotmail.com> - 3.3.1-2
- Simplify permissions, both kafka and zookeeper need to read/write the same directories, share the same username & group

* Mon Oct 24 2022 "Brandon Dunne" <bdunne@redhat.com> - 3.3.1-1
- Upgrade to v3.3.1

* Fri Jul 08 2022 "Adam Grare" <adam@grare.com> - 3.2.0-1
- Upgrade to v3.2.0

* Wed Nov 11 2020 "Brandon Dunne" <bdunne@redhat.com> - 2.3.1-2
- Copy modified server.properties and zookeeper.properties config files to config-sample

* Wed Nov 20 2019 "Brandon Dunne" <bdunne@redhat.com> - 2.3.1-1
- Initial commit
