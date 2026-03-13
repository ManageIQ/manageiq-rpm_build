%global proton_datadir %{_datadir}/proton
%global gem_name qpid_proton
%global __cmake_in_source_build 1

%global __provides_exclude_from ^%{proton_datadir}/examples/.*$
%global __requires_exclude_from ^%{proton_datadir}/examples/.*$

%undefine __brp_mangle_shebangs

Name:           qpid-proton
Version:        0.37.0
Release:        1%{?dist}
Summary:        A high performance, lightweight messaging library
License:        ASL 2.0
URL:            http://qpid.apache.org/proton/

Source0:        %{name}-%{version}.tar.gz
Patch0:         proton.patch

Source1:        licenses.xml

%global proton_licensedir %{_licensedir}/proton
%{!?_licensedir:%global license %doc}
%{!?_licensedir:%global proton_licensedir %{proton_datadir}}

BuildRequires:  make
BuildRequires:  gcc
BuildRequires:  gcc-c++
BuildRequires:  cmake
BuildRequires:  swig
BuildRequires:  pkgconfig
BuildRequires:  doxygen
BuildRequires:  libuuid-devel
BuildRequires:  openssl-devel
BuildRequires:  python3-devel
BuildRequires:  python3-sphinx
BuildRequires:  glibc-headers
BuildRequires:  cyrus-sasl-devel
BuildRequires:  jsoncpp-devel
BuildRequires:  python3-setuptools
BuildRequires:  ruby-devel
BuildRequires:  rubygems-devel
BuildRequires:  libuv-devel
BuildRequires:  nspr-devel

%description
Proton is a high performance, lightweight messaging library. It can be used in
the widest range of messaging applications including brokers, client libraries,
routers, bridges, proxies, and more. Proton is based on the AMQP 1.0 messaging
standard. Using Proton it is trivial to integrate with the AMQP 1.0 ecosystem
from any platform, environment, or language.


%package c
Summary:   C libraries for Qpid Proton
Requires:  cyrus-sasl-lib
Obsoletes: qpid-proton
Obsoletes: perl-qpid-proton

%description c
%{summary}.


%files c
%dir %{proton_datadir}
%license %{proton_licensedir}/LICENSE.txt
%license %{proton_licensedir}/licenses.xml
%doc %{proton_datadir}/README*
%{_libdir}/libqpid-proton.so.*
%{_libdir}/libqpid-proton-core.so.*
%{_libdir}/libqpid-proton-proactor.so.*

%ldconfig_scriptlets c


%package   cpp
Summary:   C++ libraries for Qpid Proton
Requires:  qpid-proton-c%{?_isa} = %{version}-%{release}
Requires:  jsoncpp

%description cpp
%{summary}.

%files cpp
%dir %{proton_datadir}
%doc %{proton_datadir}/README*
%{_libdir}/libqpid-proton-cpp.so.*

%ldconfig_scriptlets cpp


%package c-devel
Requires:  qpid-proton-c%{?_isa} = %{version}-%{release}
Summary:   Development libraries for writing messaging apps with Qpid Proton
Obsoletes: qpid-proton-devel

%description c-devel
%{summary}.

%files c-devel
%{_includedir}/proton
%exclude %{_includedir}/proton/*.hpp
%exclude %{_includedir}/proton/**/*.hpp
%{_libdir}/libqpid-proton.so
%{_libdir}/libqpid-proton-core.so
%{_libdir}/libqpid-proton-proactor.so
%{_libdir}/pkgconfig/libqpid-proton.pc
%{_libdir}/pkgconfig/libqpid-proton-core.pc
%{_libdir}/pkgconfig/libqpid-proton-proactor.pc
%{_libdir}/cmake/Proton


%package cpp-devel
Requires:  qpid-proton-cpp%{?_isa} = %{version}-%{release}
Requires:  qpid-proton-c-devel%{?_isa} = %{version}-%{release}
Summary:   Development libraries for writing messaging apps with Qpid Proton

%description cpp-devel
%{summary}.

%files cpp-devel
%{_includedir}/proton/*.hpp
%{_includedir}/proton/**/*.hpp
%{_libdir}/pkgconfig/libqpid-proton-cpp.pc
%{_libdir}/libqpid-proton-cpp.so
%{_libdir}/cmake/ProtonCpp


%package c-docs
Summary:   Documentation for the C development libraries for Qpid Proton
BuildArch: noarch
Obsoletes: qpid-proton-c-devel-doc
Obsoletes: qpid-proton-c-devel-docs

%description c-docs
%{summary}.

%files c-docs
%license %{proton_licensedir}/LICENSE.txt
%doc %{proton_datadir}/docs/api-c
%doc %{proton_datadir}/examples/README.md
%doc %{proton_datadir}/examples/c/ssl-certs
%doc %{proton_datadir}/examples/c/*.c
%doc %{proton_datadir}/examples/c/*.h
%doc %{proton_datadir}/examples/c/README.dox
%doc %{proton_datadir}/examples/c/CMakeLists.txt


%package   cpp-docs
Summary:   Documentation for the C++ development libraries for Qpid Proton
BuildArch: noarch
Obsoletes: qpid-proton-cpp-devel-doc
Obsoletes: qpid-proton-cpp-devel-docs

%description cpp-docs
%{summary}.

%files cpp-docs
%license %{proton_licensedir}/LICENSE.txt
%{proton_datadir}/docs/api-cpp
%doc %{proton_datadir}/examples/cpp/*.cpp
%doc %{proton_datadir}/examples/cpp/*.hpp
%doc %{proton_datadir}/examples/cpp/README.dox
%doc %{proton_datadir}/examples/cpp/CMakeLists.txt
%doc %{proton_datadir}/examples/cpp/ssl-certs
%doc %{proton_datadir}/examples/cpp/tutorial.dox


%package -n python3-qpid-proton
Summary:  Python language bindings for the Qpid Proton messaging framework
Requires: qpid-proton-c%{?_isa} = %{version}-%{release}
Requires: python3

%description -n python3-qpid-proton
%{summary}.

%files -n python3-qpid-proton
%{python3_sitearch}/__pycache__/*
%{python3_sitearch}/*.so
%{python3_sitearch}/*.py*
%{python3_sitearch}/*.egg-info
%{python3_sitearch}/proton


%package -n python-qpid-proton-docs
Summary:   Documentation for the Python language bindings for Qpid Proton
BuildArch: noarch
Obsoletes:  python-qpid-proton-doc

%description -n python-qpid-proton-docs
%{summary}.

%files -n python-qpid-proton-docs
%license %{proton_licensedir}/LICENSE.txt
%doc %{proton_datadir}/docs/api-py
%doc %{proton_datadir}/examples/python


%package tests
Summary:   Qpid Proton Tests
BuildArch: noarch
%description tests
%{summary}.

%files tests
%doc %{proton_datadir}/tests

%package -n rubygem-%{gem_name}
Summary: Ruby language bindings for the Qpid Proton messaging framework
Requires:   qpid-proton-c = %{version}-%{release}
Obsoletes:  rubygem-%{gem_name}-doc

%description -n rubygem-%{gem_name}
Proton is a high performance, lightweight messaging library. It can be used in
the widest range of messaging applications including brokers, client libraries,
routers, bridges, proxies, and more. Proton is based on the AMQP 1.0 messaging
standard.

%files -n rubygem-%{gem_name}
%dir %{gem_instdir}
%{gem_libdir}
%{gem_extdir_mri}
%exclude %{gem_cache}
%{gem_spec}
%doc %{gem_instdir}/examples
%doc %{gem_instdir}/tests


%prep
%setup -q -n %{name}-%{version}
%patch0 -p1


%build

mkdir build
cd build
%cmake \
    -DSYSINSTALL_BINDINGS=ON \
    -DCMAKE_SKIP_RPATH:BOOL=OFF \
    "-DCMAKE_C_FLAGS=$CFLAGS -Wno-deprecated-declarations" \
     -DENABLE_FUZZ_TESTING=NO \
    ..
make all docs %{?_smp_mflags}
(cd python/dist; %py3_build)


%install
rm -rf %{buildroot}

cd build
%make_install
(cd python/dist; %py3_install)

chmod +x %{buildroot}%{python3_sitearch}/_cproton.so

install -dm 755 %{buildroot}%{proton_licensedir}
install -pm 644 %{SOURCE1} %{buildroot}%{proton_licensedir}
install -pm 644 %{buildroot}%{proton_datadir}/LICENSE.txt %{buildroot}%{proton_licensedir}
rm -f %{buildroot}%{proton_datadir}/LICENSE.txt

cd ruby/gem/
mkdir -p %{buildroot}%{gem_instdir}
install -dm 755 %{buildroot}%{gem_dir}/specifications
mkdir -p %{buildroot}%{gem_extdir_mri}
cp -a %{buildroot}%{ruby_vendorarchdir}/cproton.so %{buildroot}%{gem_extdir_mri}/
touch %{buildroot}%{gem_extdir_mri}/gem.build_complete
chmod 644 %{buildroot}%{gem_extdir_mri}/gem.build_complete
cp -a examples tests lib %{buildroot}%{gem_instdir}/
install -pm 644 %{gem_name}.gemspec %{buildroot}%{gem_spec}

# clean up files that are not shipped
rm -rf %{buildroot}%{_exec_prefix}/bindings
rm -rf %{buildroot}%{_libdir}/java
rm -rf %{buildroot}%{_libdir}/libproton-jni.so
rm -rf %{buildroot}%{_datarootdir}/java
rm -rf %{buildroot}%{_libdir}/proton.cmake
rm -rf %{buildroot}%{_libdir}/ruby
rm -rf %{buildroot}%{_datarootdir}/ruby
rm -fr %{buildroot}%{proton_datadir}/examples/CMakeFiles
rm -f  %{buildroot}%{proton_datadir}/examples/Makefile
rm -f  %{buildroot}%{proton_datadir}/examples/*.cmake
rm -fr %{buildroot}%{proton_datadir}/examples/c/CMakeFiles
rm -f  %{buildroot}%{proton_datadir}/examples/c/*.cmake
rm -f  %{buildroot}%{proton_datadir}/examples/c/Makefile
rm -f  %{buildroot}%{proton_datadir}/examples/c/Makefile.pkgconfig
rm -f  %{buildroot}%{proton_datadir}/examples/c/broker
rm -f  %{buildroot}%{proton_datadir}/examples/c/direct
rm -f  %{buildroot}%{proton_datadir}/examples/c/receive
rm -f  %{buildroot}%{proton_datadir}/examples/c/send
rm -f  %{buildroot}%{proton_datadir}/examples/c/send-abort
rm -f  %{buildroot}%{proton_datadir}/examples/c/send-ssl
rm -f  %{buildroot}%{proton_datadir}/examples/c/raw_connect
rm -f  %{buildroot}%{proton_datadir}/examples/c/raw_echo
rm -fr %{buildroot}%{proton_datadir}/examples/cpp/CMakeFiles
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/*.cmake
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/Makefile
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/Makefile.pkgconfig
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/broker
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/client
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/connection_options
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/direct_recv
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/direct_send
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/encode_decode
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/flow_control
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/helloworld
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/helloworld_direct
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/queue_browser
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/scheduled_send_03
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/scheduled_send
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/selected_recv
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/server
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/server_direct
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/service_bus
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/simple_connect
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/simple_recv
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/simple_send
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/ssl
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/ssl_client_cert
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/message_properties
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/multithreaded_client
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/multithreaded_client_flow_control
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/reconnect_client
rm -f  %{buildroot}%{proton_datadir}/examples/cpp/colour_send
rm -fr %{buildroot}%{proton_datadir}/examples/engine/java
rm -fr %{buildroot}%{proton_datadir}/examples/go
rm -fr %{buildroot}%{proton_datadir}/examples/java
rm -fr %{buildroot}%{proton_datadir}/examples/javascript
rm -fr %{buildroot}%{proton_datadir}/examples/ruby
rm -fr %{buildroot}%{proton_datadir}/examples/perl
rm -fr %{buildroot}%{proton_datadir}/examples/php
rm -f  %{buildroot}%{proton_datadir}/CMakeLists.txt

%check

%changelog
* Tue Jul 12 2022 Irina Boverman <iboverma@redhat.com> - 0.37.0-1
- Initial build for EPEL 9
