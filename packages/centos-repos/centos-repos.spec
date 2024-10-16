Name:           centos-repos
Version:        8
Release:        6.1%{?dist}
Summary:        CentOS package repositories
License:        GPLv2
URL:            https://centos.org
BuildArch:      noarch

Source100:      LICENSE
Source101:      RPM-GPG-KEY-centosofficial
Source102:      RPM-GPG-KEY-centostesting
Source103:      RPM-GPG-KEY-CentOS-SIG-Extras

# CentOS Linux repos
Source200:      CentOS-Linux-BaseOS.repo
Source201:      CentOS-Linux-AppStream.repo
Source202:      CentOS-Linux-PowerTools.repo
Source203:      CentOS-Linux-Extras.repo
Source204:      CentOS-Linux-Plus.repo

# CentOS Linux add-on repos
Source210:      CentOS-Linux-HighAvailability.repo

# CentOS Linux special repos
Source220:      CentOS-Linux-Media.repo
Source221:      CentOS-Linux-Debuginfo.repo
Source222:      CentOS-Linux-Sources.repo
Source223:      CentOS-Linux-Devel.repo
Source224:      CentOS-Linux-ContinuousRelease.repo
Source225:      CentOS-Linux-FastTrack.repo

# CentOS Stream repos
Source300:      CentOS-Stream-BaseOS.repo
Source301:      CentOS-Stream-AppStream.repo
Source302:      CentOS-Stream-PowerTools.repo
Source303:      CentOS-Stream-Extras.repo
Source304:      CentOS-Stream-Extras-common.repo

# CentOS Stream add-on repos
Source310:      CentOS-Stream-HighAvailability.repo
Source311:      CentOS-Stream-RealTime.repo
Source312:      CentOS-Stream-ResilientStorage.repo
Source313:      CentOS-Stream-NFV.repo

# CentOS Stream special repos
Source320:      CentOS-Stream-Media.repo
Source321:      CentOS-Stream-Debuginfo.repo
Source322:      CentOS-Stream-Sources.repo


%description
This package provides the package repository files for CentOS.


%package -n centos-linux-repos
Summary:        CentOS Linux package repositories
Requires:       system-release(releasever) = %{version}
Requires:       centos-gpg-keys = 1:%{version}-%{release}
Provides:       centos-repos(%{version})

# files previously located in other packages
Conflicts:      centos-release < 8.0-0.1905.0.10
Conflicts:      centos-repos < 8.2-3

# conflict with virtual provide so only one repos package is installed
Conflicts:      centos-repos(%{version})

# give dnf a hint to resolve this package on CentOS Linux
Enhances:       centos-linux-release


%description -n centos-linux-repos
This package provides the package repository files for CentOS Linux.


%package -n centos-stream-repos
Summary:        CentOS Stream package repositories
Requires:       system-release(releasever) = %{version}
Requires:       centos-gpg-keys = 1:%{version}-%{release}
Provides:       centos-repos(%{version})

# files previously located in other packages
Conflicts:      centos-release-stream < 8.3-4

# conflict with virtual provide so only one repos package is installed
Conflicts:      centos-repos(%{version})

# give dnf a hint to resolve this package on CentOS Stream
Enhances:       centos-stream-release


%description -n centos-stream-repos
This package provides the package repository files for CentOS Stream.


%package -n centos-gpg-keys
Summary:        CentOS RPM keys

# upgrade path from 8.2 (the version as a centos-release subpackage) to 8 (the version here)
Epoch:          1

# upgrade path from centos-release
Conflicts:      centos-release < 8.0-0.1905.0.10


%description -n centos-gpg-keys
This package provides the RPM signature keys for CentOS.


%install
# copy license here for %%license macro
cp %{SOURCE100} .

# copy GPG keys
install -d -m 0755 %{buildroot}%{_sysconfdir}/pki/rpm-gpg
install -p -m 0644 %{_sourcedir}/RPM-GPG-KEY-* %{buildroot}%{_sysconfdir}/pki/rpm-gpg/

# copy yum repos
install -d -m 0755 %{buildroot}%{_sysconfdir}/yum.repos.d
install -p -m 0644 %{_sourcedir}/*.repo %{buildroot}%{_sysconfdir}/yum.repos.d/

# dnf variables
install -d -m 0755 %{buildroot}%{_sysconfdir}/dnf/vars
echo "stock" > %{buildroot}%{_sysconfdir}/dnf/vars/infra
echo "centos" >%{buildroot}%{_sysconfdir}/dnf/vars/contentdir
echo "%{version}-stream" > %{buildroot}%{_sysconfdir}/dnf/vars/stream


%files -n centos-linux-repos
%license LICENSE
%dir %{_sysconfdir}/yum.repos.d
%config(noreplace) %{_sysconfdir}/yum.repos.d/CentOS-Linux-*.repo
%config(noreplace) %{_sysconfdir}/dnf/vars/contentdir
%config(noreplace) %{_sysconfdir}/dnf/vars/infra


%files -n centos-stream-repos
%license LICENSE
%dir %{_sysconfdir}/yum.repos.d
%config(noreplace) %{_sysconfdir}/yum.repos.d/CentOS-Stream-*.repo
%config(noreplace) %{_sysconfdir}/dnf/vars/contentdir
%config(noreplace) %{_sysconfdir}/dnf/vars/infra
%config(noreplace) %{_sysconfdir}/dnf/vars/stream


%files -n centos-gpg-keys
%{_sysconfdir}/pki/rpm-gpg/


%changelog
* Wed Oct 16 2024 Brandon Dunne <brandondunne@hotmail.com> - 8-6.1
- Switch to CentOS Vault since Stream8 is EOL

* Fri Mar 25 2022 Fabian Arrotin <arrfab@centos.org> - 8-6
- Extras-common is now its own .repo file for easy consumption

* Tue Mar 15 2022 Fabian Arrotin <arrfab@centos.org> - 8-5
- Added new extras-common repo and dedicated SIG Extras key

* Wed Jan 19 2022 bstinson@redhat.com - 8-4
- Add the NFV addon to CentOS Stream 8

* Tue Sep 14 2021 Carl George <carl@george.computer> - 8-3
- Add resilientstorage repo to centos-stream-repos
- Add source repos to centos-stream-repos
- Add powertools-source repo to centos-linux-repos

* Mon Sep 28 2020 Carl George <carl@george.computer> - 8-2
- Remove plus repo file from centos-stream-repos

* Fri Sep 11 2020 Carl George <carl@george.computer> - 8-1
- Convert to centos-repos

* Fri May 15 2020 Pablo Greco <pgreco@centosproject.org> - 8-2.0.1
- Relax dependency for centos-repos
- Remove update_boot, it was never used in 8
- Add rootfs_expand to aarch64
- Bump release for 8.2

* Thu Mar 12 2020 bstinson@centosproject.org - 8-1.0.9
- Add the Devel repo to centos-release
- Install os-release(5) content to /usr/lib and have /etc/os-release be a symlink (ngompa)pr#9

* Thu Jan 02 2020 Brian Stinson <bstinson@centosproject.org> - 8-1.0.8
- Add base module platform Provides so DNF can auto-discover modular platform (ngompa)pr#6
- Switched CR repo to mirrorlist to spread the load (arrfab)pr#5

* Thu Dec 19 2019 bstinson@centosproject.org - 8-1.0.7
- Typo fixes
- Disable the HA repo by default

* Wed Dec 18 2019 Pablo Greco <pgreco@centosproject.org> - 8-1.el8
- Fix requires in armhfp

* Tue Dec 17 2019 bstinson@centosproject.org - 8-1.el8
- Add the HighAvailability repository

* Wed Aug 14 2019 Neal Gompa <ngompa@centosproject.org> 8-1.el8
- Split repositories and GPG keys out into subpackages

* Sat Aug 10 2019 Fabian Arrotin <arrfab@centos.org> 8-0.el8
- modified baseurl paths, even if disabled

* Sat Aug 10 2019 Fabian Arrotin <arrfab@centos.org> 8-0.el8
- Enabled Extras by default.
- Fixed sources paths for BaseOS/AppStream

* Sat Aug 10 2019 Brian Stinson <bstinson@centosproject.org> 8-0.el7
- Update Debuginfo and fasttrack to use releasever
- Fix CentOS-media.repo to include appstream

* Wed May 08 2019 Pablo Greco <pablo@fliagreco.com.ar> 8-0.el7
- Initial setup for CentOS-8
