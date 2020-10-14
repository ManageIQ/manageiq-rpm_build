Name:             kafka
Summary:          Apache Kafka is an open-source stream-processing software platform
Version:          2.3.1
Release:          1
License:          Apache (v2)
Group:            Applications
URL:              https://kafka.apache.org
BuildRequires:    java-1.8.0-openjdk-devel >= 1.8
Requires:         jre >= 1.8
Requires(post):   systemd
Requires(postun): systemd
Requires(preun):  systemd
Source0:          http://archive.apache.org/dist/%{name}/%{version}/%{name}-%{version}-src.tgz
Source1:          https://services.gradle.org/distributions/gradle-%{gradle_version}-bin.zip
Source2:          kafka.service
Source3:          zookeeper.service
Provides:         kafka
BuildRoot:        %{_tmppath}/%{name}-%{version}-root


%global debug_package %{nil}
%define __jar_repack 0
%define gradle_version 5.6.4
%define kafka_home /opt/kafka
%define kafka_group %{name}
%define kafka_user %{name}
%define zookeeper_group zookeeper
%define zookeeper_user zookeeper


%description
Kafka® is used for building real-time data pipelines and streaming apps. It is horizontally scalable, fault-tolerant, wicked fast, and runs in production in thousands of companies.


%pre
groupadd -fr %{kafka_group}
getent passwd %{kafka_user} >/dev/null || useradd -r -g %{kafka_group} -d %{_sharedstatedir}/kafka -s /sbin/nologin -c "User for kafka services" %{kafka_user}
groupadd -fr %{zookeeper_group}
getent passwd %{zookeeper_user} >/dev/null || useradd -r -g %{zookeeper_group} -d %{_sharedstatedir}/zookeeper -s /sbin/nologin -c "User for zookeeper services" %{zookeeper_user}


%prep
%setup -q -n %{name}-%{version}-src


%build
unzip %{_sourcedir}/gradle-%{gradle_version}-bin.zip
./gradle-%{gradle_version}/bin/gradle
./gradlew jar


%install
mkdir -p %{buildroot}%{kafka_home}
mkdir -p %{buildroot}%{kafka_home}/config
mkdir -p %{buildroot}%{kafka_home}/libs
mkdir -p %{buildroot}%{_localstatedir}/log/kafka
mkdir -p %{buildroot}%{_sharedstatedir}/kafka
mkdir -p %{buildroot}%{_localstatedir}/log/zookeeper
mkdir -p %{buildroot}%{_sharedstatedir}/zookeeper

rm -rf bin/windows
cp LICENSE %{buildroot}%{kafka_home}
cp NOTICE %{buildroot}%{kafka_home}
cp -r bin %{buildroot}%{kafka_home}
cp -r config %{buildroot}%{kafka_home}/config-sample
sed "s,log.dirs=.*,log.dirs=%{_sharedstatedir}/kafka," config/server.properties > %{buildroot}%{kafka_home}/config/server.properties
sed "s,dataDir=.*,dataDir=%{_sharedstatedir}/zookeeper," config/zookeeper.properties > %{buildroot}%{kafka_home}/config/zookeeper.properties
cp config/log4j.properties %{buildroot}%{kafka_home}/config
cp -n */build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */build/dependant-libs*/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/libs/* %{buildroot}%{kafka_home}/libs
cp -n */*/build/dependant-libs*/* %{buildroot}%{kafka_home}/libs

# Install systemd units
install -m755 -d %{buildroot}%{_unitdir}
install -pm644 %SOURCE2 %SOURCE3 %{buildroot}%{_unitdir}/


%files
%defattr(-,root,root)
%{_unitdir}/kafka.service
%{_unitdir}/zookeeper.service
%{kafka_home}
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_sharedstatedir}/kafka
%config %attr(-, %{kafka_user}, %{kafka_group}) %{_localstatedir}/log/kafka
%config %attr(-, %{zookeeper_user}, %{zookeeper_group}) %{_sharedstatedir}/zookeeper
%config %attr(-, %{zookeeper_user}, %{zookeeper_group}) %{_localstatedir}/log/zookeeper


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
* Wed Nov 20 2019 "Brandon Dunne" <bdunne@redhat.com>
- Initial commit
