Name:             kafka
Summary:          Apache Kafka is an open-source stream-processing software platform
Version:          3.9.1
Release:          1%{?dist}
License:          Apache (v2)
Group:            Applications
URL:              https://kafka.apache.org
BuildRequires:    git
BuildRequires:    java-21-openjdk-devel
BuildRequires:    systemd-rpm-macros
Requires:         java-21-openjdk-headless
Requires(post):   systemd
Requires(postun): systemd
Requires(preun):  systemd
Source0:          http://archive.apache.org/dist/%{name}/%{version}/%{name}-%{version}-src.tgz
Source1:          kafka.service
Source2:          zookeeper.service
Source3:          kafka.sysusers
Patch0:           0001-move_config_to_etc.patch
Provides:         kafka
BuildRoot:        %{_tmppath}/%{name}-%{version}-root


%global debug_package %{nil}
%define __jar_repack 0
%define etc_kafka %{_sysconfdir}/kafka
%define kafka_home /opt/kafka
%define kafka_group %{name}
%define kafka_user %{name}
%{?sysusers_requires_compat}


%description
Kafka® is used for building real-time data pipelines and streaming apps. It is horizontally scalable, fault-tolerant, wicked fast, and runs in production in thousands of companies.


%pre
%sysusers_create_compat %{SOURCE3}


%prep
%autosetup -n %{name}-%{version}-src -S git


%build
./gradlew jar


%install
mkdir -p %{buildroot}%{etc_kafka}
mkdir -p %{buildroot}%{etc_kafka}/config
mkdir -p %{buildroot}%{etc_kafka}/keystore
mkdir -p %{buildroot}%{kafka_home}
mkdir -p %{buildroot}%{kafka_home}/libs
mkdir -p %{buildroot}%{_localstatedir}/log/kafka
mkdir -p %{buildroot}%{_sharedstatedir}/kafka
mkdir -p %{buildroot}%{_localstatedir}/log/zookeeper
mkdir -p %{buildroot}%{_sharedstatedir}/zookeeper
mkdir -p %{buildroot}%{_usr}/local

rm -rf bin/windows
cp LICENSE %{buildroot}%{kafka_home}
cp NOTICE %{buildroot}%{kafka_home}
cp -r bin %{buildroot}%{kafka_home}
cp -r config %{buildroot}%{etc_kafka}/config-sample
cp config/log4j.properties %{buildroot}%{etc_kafka}/config
cp config/server.properties %{buildroot}%{etc_kafka}/config
cp config/tools-log4j.properties %{buildroot}%{etc_kafka}/config
cp config/zookeeper.properties %{buildroot}%{etc_kafka}/config
cp -n */build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */build/dependant-libs*/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/dependant-libs*/* %{buildroot}%{kafka_home}/libs


# Install systemd units
install -m755 -d %{buildroot}%{_unitdir}
install -pm644 %SOURCE1 %SOURCE2 %{buildroot}%{_unitdir}/

# Install the sysuser config file
install -p -D -m 0644 %{SOURCE3} %{buildroot}%{_sysusersdir}/kafka.conf


%files
%defattr(-,root,root)
%{_unitdir}/kafka.service
%{_unitdir}/zookeeper.service
%{kafka_home}
%config %attr(-, %{kafka_user}, %{kafka_group}) %{etc_kafka}
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_sharedstatedir}/kafka
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_localstatedir}/log/kafka
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_sharedstatedir}/zookeeper
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_localstatedir}/log/zookeeper
%{_sysusersdir}/kafka.conf


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
* Thu Apr 2 2026 "Brandon Dunne" <brandondunne@hotmail.com> - 3.9.1-1
- Upgrade to v3.9.1
- Changes to support EL10 bootc
- Switch to sysuser config file for user and group creation

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
