Name:      manageiq-release
Version:   15.0
Release:   1%{dist}
Summary:   ManageIQ RPM repository configuration
License:   Apache-2.0
URL:       https://rpm.manageiq.org/release/
Source0:   RPM-GPG-KEY-MANAGEIQ
Source1:   manageiq-15-oparin.repo
BuildArch: noarch

%description
This package contains the ManageIQ repository GPG key as well as configuration for yum.

%prep
%setup -q -c -T
install -pm 644 %{SOURCE0} .

%build

%install
rm -rf $RPM_BUILD_ROOT

#GPG Key
install -Dpm 644 %{SOURCE0} $RPM_BUILD_ROOT%{_sysconfdir}/pki/rpm-gpg/RPM-GPG-KEY-MANAGEIQ

# yum
install -dm 755 $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d
install -pm 644 %{SOURCE1} $RPM_BUILD_ROOT%{_sysconfdir}/yum.repos.d

%clean
rm -rf $RPM_BUILD_ROOT

%files
%defattr(-,root,root,-)
%config(noreplace) /etc/yum.repos.d/*
/etc/pki/rpm-gpg/*

%changelog
* Mon Feb 14 2022 Jason Frey <fryguy9@gmail.com> - 15.0-1%{dist}
- Initial build of manageiq-release for Oparin.

* Fri Sep 10 2021 Brandon Dunne <brandondunne@hotmail.com> - 14.0-2%{dist}
- Fix repo url for Najdorf nightly

* Wed Sep 1 2021 Brandon Dunne <brandondunne@hotmail.com> - 14.0-1%{dist}
- Initial build of manageiq-release for Najdorf

* Mon Feb 22 2021 Jason Frey <fryguy9@gmail.com> - 13.0-1%{dist}
- Initial build of manageiq-release for Morphy.

* Tue Oct 27 2020 Satoe Imaishi <simaishi@redhat.com> - 12.0-1%{dist}
- Initial build of manageiq-release for Lasker.

* Thu May 14 2020 Brandon Dunne <brandondunne@hotmail.com> - 11.0-1%{dist}
- Initial build of manageiq-release for Kasparov.

* Wed May 13 2020 Brandon Dunne <brandondunne@hotmail.com> - 10.0-1%{dist}
- Initial build of manageiq-release for Jansa.
