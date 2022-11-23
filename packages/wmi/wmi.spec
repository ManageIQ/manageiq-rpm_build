Summary: WMI client for Linux
Name: wmi
Version: 1.3.14
Release: 2%{dist}
BuildArch: x86_64
Group: System Environment/Libraries
License: GPL
Source: %{name}-%{version}.tar.bz2
Patch0: openvas-wmi-%{version}.patch
BuildRoot: %{_tmppath}/%{name}-%{version}-root
Vendor: Atomicorp, http://www.atomicorp.com

BuildRequires: autoconf

%description
WMI client and libraries.

%prep
%setup
%patch0 -p1

# nerwer version of perl doesn't support 'defined(@array)'
sed -i '583s/defined //' Samba/source/pidl/pidl

# Fix for empty debugsourcefiles.list
sed -i 's/DHAVE_CONFIG_H/DHAVE_CONFIG_H \-g/' Samba/source/build/smb_build/makefile.pm

# create the pkgconfig
%{__cat} <<EOF > wmiclient.pc

prefix=%{_prefix}
exec_prefix=%{_prefix}
libdir=%{_libdir}
includedir=%{_prefix}/include

Name: wmiclient
Description: wmiclient library for OpenVAS
 Version: 1.3.14
 Requires:
Cflags: -I%{_includedir} -I%{_includedir}/openvas
Libs: -L%{_libdir}
EOF


%build
ulimit -n 500000
cd Samba/source
 ./autogen.sh
./configure
make proto all "CPP=gcc -E -ffreestanding"
make libraries "CPP=gcc -E -ffreestanding"

# Cleanup linking 
pushd wmi
  ln -sf libwmiclient.so.1 libwmiclient.so 
popd

%install
make "DESTDIR=${RPM_BUILD_ROOT}" install

mkdir -p  $RPM_BUILD_ROOT/%{_libdir}/
mkdir -p  $RPM_BUILD_ROOT/%{_libdir}/pkgconfig
%{__install} -m 0644 wmiclient.pc $RPM_BUILD_ROOT/%{_libdir}/pkgconfig/wmiclient.pc
%{__install} -m 0755 Samba/source/wmi/libwmiclient.so.1 $RPM_BUILD_ROOT/%{_libdir}/libwmiclient.so.1
%{__install} -m 0755 Samba/source/wmi/libwmiclient.so $RPM_BUILD_ROOT/%{_libdir}/libwmiclient.so



%post
/sbin/ldconfig

%postun
/sbin/ldconfig


%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
/bin/winexe
/bin/wmic
/lib/python/libasync_wmi_lib.so.*
/lib/python/pysamba/*
%{_libdir}/pkgconfig/wmiclient.pc
%{_libdir}/libwmiclient.so*


%changelog
* Fri Nov 15 2019 Satoe Imaishi <simaishi@redhat.com> 1.3.14-2
- CentOS 8 build

* Mon Mar 16 2015 Joe VLcek <jvlcek@redhat.com> 1.3.13-1
- Initial build
