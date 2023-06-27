# TODO: Re-enable docs and tests once possible
%global with_docs 0
%global with_tests 0
%global ansible_licensedir %{_defaultlicensedir}/ansible
%global ansible_docdir %{_defaultdocdir}/ansible

# This should be updated after each release to match upstream's metadata
# https://github.com/ansible-community/community-topics/issues/84
%global ansible_core_version 2.12.2
%global ansible_core_next_version 2.13
%global ansible_core_requires (ansible-core >= %{ansible_core_version} with ansible-core < %{ansible_core_next_version})

%if 0%{?rhel} == 8
# RHEL 8's ansible-core package is built using Python 3.8, which is not the default version.
%define python3_pkgversion 38
BuildRequires:  python%{python3_pkgversion}-rpm-macros

# RHEL 8's RPM Python dependency generator ignores the version constraints, so we manually specify the dependency.
%{?python_disable_dependency_generator}
Requires:       %{ansible_core_requires}
%endif

Name:           ansible
Summary:        Curated set of Ansible collections included in addition to ansible-core
Version:        5.4.0
Release:        3%{?dist}

License:        GPLv3+
Source0:        %{pypi_source}
Url:            https://ansible.com
BuildArch:      noarch

BuildRequires:  findutils
BuildRequires:  python%{python3_pkgversion}-devel
BuildRequires:  python%{python3_pkgversion}-setuptools
BuildRequires:  %{ansible_core_requires}

%if 0%{?with_tests}
# TODO build-requires
%endif

%if 0%{?with_docs}
# TODO build-requires
%endif

%description
Ansible is a radically simple model-driven configuration management,
multi-node deployment, and remote task execution system. Ansible works
over SSH and does not require any software or daemons to be installed
on remote nodes. Extension modules can be written in any language and
are transferred to managed machines automatically.

This package provides a curated set of Ansible collections included in addition
to ansible-core.

%prep
%autosetup

# Remove unnecessary files and directories included in the Ansible collection release tarballs
# Tracked upstream in part by: https://github.com/ansible-community/community-topics/issues/29
echo "[START] Delete unnecessary files and directories"

# Collection tarballs contain a lot of hidden files and directories
hidden_pattern=".*\.(DS_Store|all-contributorsrc|ansible-lint|azure-pipelines|circleci|codeclimate.yml|flake8|galaxy_install_info|gitattributes|github|gitignore|gitkeep|gitlab-ci.yml|idea|keep|mypy_cache|nojekyll|orig|plugin-cache.yaml|pre-commit-config.yaml|project|pydevproject|pytest_cache|pytest_cache|readthedocs.yml|settings|swp|travis.yml|vscode|yamllint|yamllint.yaml|zuul.d|zuul.yaml)$"
find ansible_collections -regextype posix-egrep -regex "${hidden_pattern}" -print -depth -exec rm -rf {} \;

# TODO: Delete (bulky) tests for now but we should run sanity and unit tests soon.
find ansible_collections -type d -wholename "*tests/integration" -print -depth -exec rm -rf {} \;
find ansible_collections -type d -wholename "*tests/unit" -print -depth -exec rm -rf {} \;
find ansible_collections -type d -wholename "*tests/sanity" -print -depth -exec rm -rf {} \;
find ansible_collections -type d -wholename "*tests/regression" -print -depth -exec rm -rf {} \;

# https://github.com/ansible-collections/kubernetes.core/pull/298
rm -rf ansible_collections/kubernetes/core/molecule

# rpmlint W: pem-certificate
find ansible_collections/cyberark/conjur -type f -name "*.pem" -print -delete

# rpmlint E: zero-length
find -type f -name "*requirements.txt" -size 0 -print -delete
rm -f ansible_collections/community/zabbix/roles/zabbix_agent/files/win_sample/doSomething.ps1

echo "[END] Delete unnecessary files and directories"

%build
# disable the python -s shbang flag as we want to be able to find non system modules
%global py3_shbang_opts %{nil}
%py3_shebang_fix ansible_collections
%py3_build

%install
%py3_install

# Install docs and licenses
(
  mkdir -p "%{buildroot}%{ansible_docdir}" "%{buildroot}%{ansible_licensedir}"
  cd ansible_collections
  # This finds the license file for each collection, copies it to
  # `%%{ansible_licensedir}/collection_namespace/collection_name`, and then adds
  # `%%license /path/to/license` to the %%files list. See `man find` for more info.
  # The extra percent signs are needed to escape RPM.
  find . -mindepth 3 -type f \( -name LICENSE -o -name COPYING \) \
         -exec cp -p --parents '{}' '%{buildroot}%{ansible_licensedir}' \; \
         -printf '%%%%license %%%%{ansible_licensedir}/%%P\n'  | tee -a ../files.list
  # This does the same thing, but for READMEs.
  find . -mindepth 3 -type f -name 'README.*' \
         -exec cp -p --parents '{}' '%{buildroot}%{ansible_docdir}' \; \
         -printf '%%%%doc %%%%{ansible_docdir}/%%P\n' | tee -a ../files.list
)

%check
%if 0%{?with_tests}
# TODO: Run tests
%endif

%files -f files.list
%license COPYING
%doc README.rst PKG-INFO porting_guide_5.rst CHANGELOG-v5.rst
# Note (dmsimard): This ansible package installs collections to the python sitelib to mirror the UX
# when installing the ansible package from PyPi.
# This allows users to install individual collections manually with ansible-galaxy (~/.ansible/collections/ansible_collections)
# or via standalone distribution packages to datadir (/usr/share).
# Both will have precedence over the collections installed in the python sitelib.
%{python3_sitelib}/ansible_collections
%{python3_sitelib}/*egg-info

%changelog
* Thu Jul 21 2022 Maxwell G <gotmax@e.email> - 5.4.0-3
- Rebuild to fix bug in epel-rpm-macros' Python dependency generator

* Mon Apr 25 2022 Maxwell G <gotmax@e.email> - 5.4.0-2
- Ensure correct version of ansible-core is available at buildtime.
- Implement support for epel8.

* Tue Feb 22 2022 David Moreau-Simard <moi@dmsimard.com> - 5.4.0-1
- Update to latest upstream release

* Wed Feb 16 2022 Maxwell G <gotmax@e.email> - 5.3.0-2
- Fix shebangs.

* Tue Feb 1 2022 David Moreau-Simard <moi@dmsimard.com> - 5.3.0-1
- Update to latest upstream release

* Wed Jan 19 2022 Fedora Release Engineering <releng@fedoraproject.org> - 5.2.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_36_Mass_Rebuild

* Wed Jan 12 2022 David Moreau-Simard <moi@dmsimard.com> - 5.2.0-1
- Update to latest upstream release

* Tue Jan 11 2022 David Moreau-Simard <moi@dmsimard.com> - 5.1.0-1
- Update to latest upstream release
- Refactor to take into account split from ansible-core after ansible 2.9, see: https://fedoraproject.org/wiki/Changes/Ansible5
- Remove patches intended for Ansible 2.9
- Removed packaging macros (soon included in ansible-packaging, see rhbz#2038591)
- Removed provides/obsoletes on ansible-python3

* Tue Oct 26 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.27-1
- Update to 2.9.27. Fixes rhbz#2012918

* Fri Aug 20 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.25-1
- Update to 2.9.25. Fixes rhbz#1994108

* Sun Jul 25 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.24-1
- Update to 2.9.24. Fixes rhbz#1983837

* Tue Jun 22 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.23-1
- Update to 2.9.23. Fixes rhbz#1974592
- Add patch for Rocky Linux. Fixes rhbz#1968728

* Mon May 24 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.22-1
- Update to 2.9.22.

* Tue May 04 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.21-1
- Update to 2.9.21.

* Sat Apr 24 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.20-1
- Update to 2.9.20.
- Split out ansible-test to a subpackage.

* Fri Mar 12 2021 Orion Poplawski <orion@nwra.com> - 2.9.18-2
- Add rpm macros and generators for collections

* Sat Feb 20 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.18-1
- Update to 2.9.18.
- Fixes: CVE-2021-20228 CVE-2021-20178 CVE-2021-20180 CVE-2021-20191

* Sun Jan 24 2021 Kevin Fenzi <kevin@scrye.com> - 2.9.17-1
- Update to 2.9.17.

* Thu Dec 17 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.16-1
- Update to 2.9.16

* Tue Nov 03 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.15-1
- Update to 2.9.15

* Wed Oct 07 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.14-1
- Update to 2.9.14

* Thu Sep 03 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.13-1
- Update to 2.9.13

* Tue Aug 11 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.12-1
- Update to 2.9.12

* Tue Jul 21 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.11-1
- Update to 2.9.11

* Sat Jun 20 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.10-2
- Add patch for rabbitmq bug: https://patch-diff.githubusercontent.com/raw/ansible/ansible/pull/50381.patch

* Thu Jun 18 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.10-1
- Update to 2.9.10.

* Tue May 12 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.9-1
- Update to 2.9.9. Fixes bug #1834582
- Fixes gathering facts on f32+ bug #1832625

* Sat Apr 18 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.7-1
- Update to 2.9.7.
- fixes CVE-2020-1733 CVE-2020-1735 CVE-2020-1740 CVE-2020-1746 CVE-2020-1753 CVE-2020-10684 CVE-2020-10685 CVE-2020-10691
- Drop the -s from the shebang to allow ansible to use locally installed modules.

* Fri Mar 06 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.6-1
- Update to 2.9.6. Fixes bug #1810373
- fixes for CVE-2020-1737, CVE-2020-1739

* Thu Feb 13 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.5-1
- Update to 2.9.5.

* Thu Jan 16 2020 Kevin Fenzi <kevin@scrye.com> - 2.9.3-1
- Update to 2.9.3.

* Sun Dec 08 2019 Kevin Fenzi <kevin@scrye.com> - 2.9.2-1
- Update to 2.9.2.

* Thu Nov 14 2019 Kevin Fenzi <kevin@scrye.com> - 2.9.1-2
- Add Requires for python3-pyyaml

* Wed Nov 13 2019 Kevin Fenzi <kevin@scrye.com> - 2.9.1-1
- Update to 2.9.1.

* Fri Nov 08 2019 Kevin Fenzi <kevin@scrye.com> - 2.9.0-2
- Supress pwsh requires added by rpm.

* Thu Oct 31 2019 Kevin Fenzi <kevin@scrye.com> - 2.9.0-1
- Update to 2.9.0.

* Thu Oct 17 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.6-1
- Update to 2.8.6.
- Rework spec file to drop old conditionals.

* Thu Oct 10 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.5-2
- Make python3-paramiko and python3-winrm Recommended so they install on Fedora and not RHEL8

* Fri Sep 13 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.5-1
- Update to 2.8.5.

* Mon Aug 19 2019 Miro Hrončok <mhroncok@redhat.com> - 2.8.4-2
- Rebuilt for Python 3.8

* Fri Aug 16 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.4-1
- Update to 2.8.4. Fixes CVE-2019-10217 and CVE-2019-10206

* Thu Jul 25 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.3-1
- Update to 2.8.3.

* Wed Jul 24 2019 Fedora Release Engineering <releng@fedoraproject.org> - 2.8.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_31_Mass_Rebuild

* Wed Jul 03 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.2-1
- Update to 2.8.2. Fixes bug #1726846

* Sun Jun 09 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.1-1
- Update to 2.8.1. Fixes bug #1718131
- Sync up Requires/Buildrequires with upstream.
- Add patch for python 3.8 building. Fixes bug #1712531
- Add patch for CVE-2019-10156.

* Fri May 17 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-2
- Fixes for various releases build/test issues.

* Fri May 17 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-1
- Update to 2.8.0 final. 
- Add datadirs for other packages to land ansible files in.

* Fri May 10 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-0.4rc3
- Update to 2.8.0 rc3.

* Thu May 02 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-0.3rc2
- Update to 2.8.0 rc2.

* Fri Apr 26 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-0.2rc1
- Update to 2.8.0 rc1.

* Mon Apr 22 2019 Kevin Fenzi <kevin@scrye.com> - 2.8.0-0.1b
- Update to 2.8.0 beta 1.

* Thu Apr 04 2019 Kevin Fenzi <kevin@scrye.com> - 2.7.10-1
- Update to 2.7.10. Fixes bug #1696379

* Thu Mar 14 2019 Kevin Fenzi <kevin@scrye.com> - 2.7.9-1
- Update to 2.7.9. Fixes bug #1688974

* Thu Feb 21 2019 Kevin Fenzi <kevin@scrye.com> - 2.7.8-1
- Update to 2.7.8. Fixes bug #1679787
- Fix for CVE-2019-3828

* Thu Feb 07 2019 Kevin Fenzi <kevin@scrye.com> - 2.7.7-1
- Update to 2.7.7. Fixes bug #1673761

* Thu Jan 31 2019 Fedora Release Engineering <releng@fedoraproject.org> - 2.7.6-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_30_Mass_Rebuild

* Thu Jan 17 2019 Kevin Fenzi <kevin@scrye.com> - 2.7.6-1
- Update to 2.7.6.

* Thu Dec 13 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.5-1
- Update to 2.7.5

* Mon Dec 03 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.4-1
- Update to 2.7.4

* Thu Nov 29 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.3-1
- Update to 2.7.3

* Thu Nov 15 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.2-1
- Update to 2.7.2.

* Mon Oct 29 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.1-1
- Update to 2.7.1.

* Thu Oct 04 2018 Kevin Fenzi <kevin@scrye.com> - 2.7.0-1
- Update to 2.7.0

* Fri Sep 28 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.5-1
- Update to 2.6.5.

* Fri Sep 07 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.4-1
- Update to 2.6.4.

* Thu Aug 16 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.3-1
- Upgrade to 2.6.3.

* Sat Jul 28 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.2-1
- Update to 2.6.2. Fixes bug #1609486

* Thu Jul 12 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2.6.1-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_29_Mass_Rebuild

* Thu Jul 05 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.1-1
- Update to 2.6.1. Fixes bug #1598602
- Fixes CVE-2018-10874 and CVE-2018-10875

* Mon Jul 02 2018 Miro Hrončok <mhroncok@redhat.com> - 2.6.0-2
- Rebuilt for Python 3.7

* Thu Jun 28 2018 Kevin Fenzi <kevin@scrye.com> - 2.6.0-1
- Update to 2.6.0. Fixes bug #1596424

* Tue Jun 26 2018 Miro Hrončok <mhroncok@redhat.com> - 2.5.5-5
- Rebuilt for Python 3.7

* Mon Jun 25 2018 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.5.5-4
- Upstream patch to build docs with older jinja2 (Fedora 27)
- Build changes to build only rst docs for modules and plugins when a distro
  doesn't have modern enough packages to build the documentation. (EPEL7)

* Tue Jun 19 2018 Miro Hrončok <mhroncok@redhat.com> - 2.5.5-3
- Rebuilt for Python 3.7

* Fri Jun 15 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.5-2
- Stop building docs on F27 as python-jinja2 is too old there.

* Thu Jun 14 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.5-1
- Update to 2.5.5. Fixes bug #1580530 and #1584927
- Fixes 1588855,1590200 (fedora) and 1588855,1590199 (epel)
  CVE-2018-10855 (security bug with no_log handling)

* Thu May 31 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.4-1
- Update to 2.5.4. Fixes bug #1584927

* Thu May 17 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.3-1
- Update to 2.5.3. Fixes bug #1579577 and #1574221

* Thu Apr 26 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.2-1
- Update to 2.5.2 with bugfixes.

* Wed Apr 18 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.1-1
- Update to 2.5.1 with bugfixes. Fixes: #1569270 #1569153 #1566004 #1566001

* Tue Mar 27 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.0-2
- Some additional python3 fixes. Thanks churchyard!

* Sat Mar 24 2018 Kevin Fenzi <kevin@scrye.com> - 2.5.0-1
- Update to 2.5.0. Fixes bug #1559852
- Spec changes/improvements with tests, docs, and conditionals.

* Fri Mar 16 2018 Miro Hrončok <mhroncok@redhat.com> - 2.4.3.0-3
- Don't build and ship Python 2 bits on EL > 7 and Fedora > 29

* Wed Feb 07 2018 Fedora Release Engineering <releng@fedoraproject.org> - 2.4.3.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_28_Mass_Rebuild

* Wed Jan 31 2018 Kevin Fenzi <kevin@scrye.com> - 2.4.3.0-1
- Update to 2.4.3. See https://github.com/ansible/ansible/blob/stable-2.4/CHANGELOG.md for full changes.

* Mon Jan 08 2018 Troy Dawson <tdawson@redhat.com> - 2.4.2.0-2
- Update conditional

* Wed Nov 29 2017 Kevin Fenzi <kevin@scrye.com> - 2.4.2.0-1
- Update to 2.4.2. See https://github.com/ansible/ansible/blob/stable-2.4/CHANGELOG.md for full changes.

* Mon Oct 30 2017 Kevin Fenzi kevin@scrye.com - 2.4.1.0-2
- Add PR to conditionalize docs building. Thanks tibbs!
- Fix up el6 patches

* Thu Oct 26 2017 Kevin Fenzi <kevin@scrye.com> - 2.4.1.0-1
- Update to 2.4.1

* Thu Oct 12 2017 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.4.0.0-3
- Fix Python3 subpackage to symlink to the python3 versions of the scripts
  instead of the python2 version

* Mon Sep 25 2017 Kevin Fenzi <kevin@scrye.com> - 2.4.0.0-2
- Rebase rhel6 jinja2 patch.
- Conditionalize jmespath to work around amazon linux issues. Fixes bug #1494640

* Tue Sep 19 2017 Kevin Fenzi <kevin@scrye.com> - 2.4.0.0-1
- Update to 2.4.0. 

* Tue Aug 08 2017 Kevin Fenzi <kevin@scrye.com> - 2.3.2.0-1
- Update to 2.3.2. Fixes bugs #1471017 #1461116 #1465586

* Wed Jul 26 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.3.1.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_27_Mass_Rebuild

* Thu Jun 01 2017 Kevin Fenzi <kevin@scrye.com> - 2.3.1.0-1
- Update to 2.3.1.0.

* Wed Apr 19 2017 James Hogarth <james.hogarth@gmail.com> - 2.3.0.0-3
- Update backported patch to the one actually merged upstream

* Wed Apr 19 2017 James Hogarth <james.hogarth@gmail.com> - 2.3.0.0-2
- Backport hotfix to fix ansible-galaxy regression https://github.com/ansible/ansible/issues/22572

* Wed Apr 12 2017 Toshio Kuratomi <toshio@fedoraproject.org> - 2.3.0.0-1
- Update to 2.3.0
- Remove upstreamed patches
- Remove controlpersist socket path path as a custom solution was included
  upstream
- Run the unittests from the upstream tarball now instead of having to download
  separately
- Build a documentation subpackage

* Tue Mar 28 2017 Kevin Fenzi <kevin@scrye.com> - 2.2.2.0-3
- Deal with RHEL7 pytest vs python-pytest.
- Rebase epel6 newer jinja patch.
- Conditionalize exclude for RHEL6 rpm.

* Tue Mar 28 2017 Kevin Fenzi <kevin@scrye.com> - 2.2.2.0-2
- Conditionalize python3 files for epel builds.

* Tue Mar 28 2017 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.2.2.0-1
- 2.2.2.0 final
- Add new patch to fix unittests

* Mon Mar 27 2017 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.2.2.0-0.4.rc1
- Add python-crypto and python3-crypto as explicit requirements

* Mon Mar 27 2017 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.2.2.0-0.3.rc1
- Add a symlink for ansible executables to be accessed via python major version
  (ie: ansible-3) in addition to python-major-minor (ansible-3.6)

* Wed Mar  8 2017 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.2.2.0-0.2.rc1
- Add a python3 ansible package.  Note that upstream doesn't intend for the library
  to be used by third parties so this is really just for the executables.  It's not
  strictly required that the executables be built for both python2 and python3 but
  we do need to get testing of the python3 version to know if it's stable enough to
  go into the next Fedora.  We also want the python2 version available in case a user
  has to get something done and the python3 version is too buggy.
- Fix Ansible cli scripts to handle appended python version

* Wed Feb 22 2017 Kevin Fenzi <kevin@scrye.com> - 2.2.2.0-0.1.rc1
- Update to 2.2.2.0 rc1. Fixes bug #1421485

* Fri Feb 10 2017 Fedora Release Engineering <releng@fedoraproject.org> - 2.2.1.0-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_26_Mass_Rebuild

* Mon Jan 16 2017 Kevin Fenzi <kevin@scrye.com> - 2.2.1.0-1
- Update to 2.2.1.
- Fixes: CVE-2016-9587 CVE-2016-8647 CVE-2016-9587 CVE-2016-8647
- Fixes bug #1405110

* Wed Nov 09 2016 Kevin Fenzi <kevin@scrye.com> - 2.2.0.0-3
- Update unit tests that will skip docker related tests if docker isn't available.
- Drop docker BuildRequires. Fixes bug #1392918

* Fri Nov  4 2016 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.2.0.0-3
- Fix for dnf group install

* Tue Nov 01 2016 Kevin Fenzi <kevin@scrye.com> - 2.2.0.0-2
- Fix some BuildRequires to work on all branches.

* Tue Nov 01 2016 Kevin Fenzi <kevin@scrye.com> - 2.2.0.0-1
- Update to 2.2.0. Fixes #1390564 #1388531 #1387621 #1381538 #1388113 #1390646 #1388038 #1390650
- Fixes for CVE-2016-8628 CVE-2016-8614 CVE-2016-8628 CVE-2016-8614

* Thu Sep 29 2016 Kevin Fenzi <kevin@scrye.com> - 2.1.2.0-1
- Update to 2.1.2

* Thu Jul 28 2016 Kevin Fenzi <kevin@scrye.com> - 2.1.1.0-1
- Update to 2.1.1

* Tue Jul 19 2016 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 2.1.0.0-3
- https://fedoraproject.org/wiki/Changes/Automatic_Provides_for_Python_RPM_Packages

* Wed Jun 15 2016 Matt Domsch <matt@domsch.com> - 2.1.0.0-2
- Force python 2.6 on EL6

* Wed May 25 2016 Kevin Fenzi <kevin@scrye.com> - 2.1.0.0-1
- Update to 2.1.0.0.
- Fixes: 1334097 1337474 1332233 1336266

* Tue Apr 19 2016 Kevin Fenzi <kevin@scrye.com> - 2.0.2.0-1
- Update to 2.0.2.0. https://github.com/ansible/ansible/blob/stable-2.0/CHANGELOG.md
- Fixes CVE-2016-3096
- Fix for failed to resolve remote temporary directory issue. bug #1328359

* Thu Feb 25 2016 Toshio Kuratomi <toshio@fedoraproject.org> - 2.0.1.0-2
- Patch control_path to be not hit path length limitations (RH BZ #1311729)
- Version the test tarball

* Thu Feb 25 2016 Toshio Kuratomi <toshio@fedoraproject.org> - 2.0.1.0-1
- Update to upstream bugfix for 2.0.x release series.

* Thu Feb  4 2016 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.0.0.2-3
- Utilize the python-jinja26 package on EPEL6

* Wed Feb 03 2016 Fedora Release Engineering <releng@fedoraproject.org> - 2.0.0.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_24_Mass_Rebuild

* Thu Jan 14 2016 Toshio Kuratomi <toshio@fedoraproject.org> - - 2.0.0.2-1
- Ansible 2.0.0.2 release from upstream.  (Minor bugfix to one callback plugin
  API).

* Tue Jan 12 2016 Toshio Kuratomi <toshio@fedoraproject.org> - 2.0.0.1-1
- Ansible 2.0.0.1 from upstream.  Rewrite with many bugfixes, rewritten code,
  and new features. See the upstream changelog for details:
  https://github.com/ansible/ansible/blob/devel/CHANGELOG.md

* Wed Oct 14 2015 Adam Williamson <awilliam@redhat.com> - 1.9.4-2
- backport upstream fix for GH #2043 (crash when pulling Docker images)

* Fri Oct 09 2015 Kevin Fenzi <kevin@scrye.com> 1.9.4-1
- Update to 1.9.4

* Sun Oct 04 2015 Kevin Fenzi <kevin@scrye.com> 1.9.3-3
- Backport dnf module from head. Fixes bug #1267018

* Tue Sep  8 2015 Toshio Kuratomi <toshio@fedoraproject.org> - 1.9.3-2
- Pull in patch for yum module that fixes state=latest issue

* Thu Sep 03 2015 Kevin Fenzi <kevin@scrye.com> 1.9.3-1
- Update to 1.9.3
- Patch dnf as package manager. Fixes bug #1258080
- Fixes bug #1251392 (in 1.9.3 release)
- Add requires for sshpass package. Fixes bug #1258799

* Thu Jun 25 2015 Kevin Fenzi <kevin@scrye.com> 1.9.2-1
- Update to 1.9.2

* Tue Jun 16 2015 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.9.1-3
- Rebuilt for https://fedoraproject.org/wiki/Fedora_23_Mass_Rebuild

* Wed May 27 2015 Toshio Kuratomi <toshio@fedoraproject.org> - 1.9.1-2
- Fix for dnf

* Tue Apr 28 2015 Kevin Fenzi <kevin@scrye.com> 1.9.1-1
- Update to 1.9.1

* Wed Mar 25 2015 Kevin Fenzi <kevin@scrye.com> 1.9.0.1-2
- Drop upstreamed epel6 patches. 

* Wed Mar 25 2015 Kevin Fenzi <kevin@scrye.com> 1.9.0.1-1
- Update to 1.9.0.1

* Wed Mar 25 2015 Kevin Fenzi <kevin@scrye.com> 1.9.0-1
- Update to 1.9.0

* Thu Feb 19 2015 Kevin Fenzi <kevin@scrye.com> 1.8.4-1
- Update to 1.8.4

* Tue Feb 17 2015 Kevin Fenzi <kevin@scrye.com> 1.8.3-1
- Update to 1.8.3

* Sun Jan 11 2015 Toshio Kuratomi <toshio@fedoraproject.org> - 1.8.2-3
- Work around a bug in python2.6 by using simplejson (applies in EPEL6)

* Wed Dec 17 2014 Michael Scherer <misc@zarb.org> 1.8.2-2
- precreate /etc/ansible/roles and /usr/share/ansible_plugins

* Sun Dec 07 2014 Kevin Fenzi <kevin@scrye.com> 1.8.2-1
- Update to 1.8.2

* Thu Nov 27 2014 Kevin Fenzi <kevin@scrye.com> 1.8.1-1
- Update to 1.8.1

* Tue Nov 25 2014 Kevin Fenzi <kevin@scrye.com> 1.8-2
- Rebase el6 patch

* Tue Nov 25 2014 Kevin Fenzi <kevin@scrye.com> 1.8-1
- Update to 1.8

* Thu Oct  9 2014 Toshio Kuratomi <toshio@fedoraproject.org> - 1.7.2-2
- Add /usr/bin/ansible to the rhel6 newer pycrypto patch

* Wed Sep 24 2014 Kevin Fenzi <kevin@scrye.com> 1.7.2-1
- Update to 1.7.2

* Thu Aug 14 2014 Kevin Fenzi <kevin@scrye.com> 1.7.1-1
- Update to 1.7.1

* Wed Aug 06 2014 Kevin Fenzi <kevin@scrye.com> 1.7-1
- Update to 1.7

* Fri Jul 25 2014 Kevin Fenzi <kevin@scrye.com> 1.6.10-1
- Update to 1.6.10

* Thu Jul 24 2014 Kevin Fenzi <kevin@scrye.com> 1.6.9-1
- Update to 1.6.9 with more shell quoting fixes.

* Tue Jul 22 2014 Kevin Fenzi <kevin@scrye.com> 1.6.8-1
- Update to 1.6.8 with fixes for shell quoting from previous release. 
- Fixes bugs #1122060 #1122061 #1122062

* Mon Jul 21 2014 Kevin Fenzi <kevin@scrye.com> 1.6.7-1
- Update to 1.6.7
- Fixes CVE-2014-4966 and CVE-2014-4967

* Tue Jul 01 2014 Kevin Fenzi <kevin@scrye.com> 1.6.6-1
- Update to 1.6.6

* Wed Jun 25 2014 Kevin Fenzi <kevin@scrye.com> 1.6.5-1
- Update to 1.6.5

* Wed Jun 25 2014 Kevin Fenzi <kevin@scrye.com> 1.6.4-1
- Update to 1.6.4

* Mon Jun 09 2014 Kevin Fenzi <kevin@scrye.com> 1.6.3-1
- Update to 1.6.3

* Sat Jun 07 2014 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.6.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_21_Mass_Rebuild

* Fri May 23 2014 Kevin Fenzi <kevin@scrye.com> 1.6.2-1
- Update to 1.6.2 release

* Wed May  7 2014 Toshio Kuratomi <toshio@fedoraproject.org> - 1.6.1-1
- Bugfix 1.6.1 release

* Mon May  5 2014 Toshio Kuratomi <toshio@fedoraproject.org> - 1.6-1
- Update to 1.6
- Drop accelerate fix, merged upstream
- Refresh RHEL6 pycrypto patch.  It was half-merged upstream.

* Fri Apr 18 2014 Kevin Fenzi <kevin@scrye.com> 1.5.5-1
- Update to 1.5.5

* Mon Apr  7 2014 Toshio Kuratomi <toshio@fedoraproject.org> - 1.5.4-2
- Fix setuptools requirement to apply to rhel=6, not rhel<6

* Wed Apr  2 2014 Toshio Kuratomi <toshio@fedoraproject.org> - 1.5.4-1
- Update to 1.5.4
- Add upstream patch to fix accelerator mode
- Merge fedora and el6 spec files

* Fri Mar 14 2014 Kevin Fenzi <kevin@scrye.com> 1.5.3-2
- Update to NEW 1.5.3 upstream release.
- Add missing dependency on python-setuptools (el6 build)

* Thu Mar 13 2014 Kevin Fenzi <kevin@scrye.com> 1.5.3-1
- Update to 1.5.3
- Fix ansible-vault for newer python-crypto dependency (el6 build)

* Tue Mar 11 2014 Kevin Fenzi <kevin@scrye.com> 1.5.2-2
- Update to redone 1.5.2 release

* Tue Mar 11 2014 Kevin Fenzi <kevin@scrye.com> 1.5.2-1
- Update to 1.5.2

* Mon Mar 10 2014 Kevin Fenzi <kevin@scrye.com> 1.5.1-1
- Update to 1.5.1

* Fri Feb 28 2014 Kevin Fenzi <kevin@scrye.com> 1.5-1
- Update to 1.5

* Wed Feb 12 2014 Kevin Fenzi <kevin@scrye.com> 1.4.5-1
- Update to 1.4.5

* Sat Dec 28 2013 Kevin Fenzi <kevin@scrye.com> 1.4.3-1
- Update to 1.4.3 with ansible galaxy commands.
- Adds python-httplib2 to requires

* Wed Nov 27 2013 Kevin Fenzi <kevin@scrye.com> 1.4.1-1
- Update to upstream 1.4.1 bugfix release

* Thu Nov 21 2013 Kevin Fenzi <kevin@scrye.com> 1.4-1
- Update to 1.4

* Tue Oct 29 2013 Kevin Fenzi <kevin@scrye.com> 1.3.4-1
- Update to 1.3.4

* Tue Oct 08 2013 Kevin Fenzi <kevin@scrye.com> 1.3.3-1
- Update to 1.3.3

* Thu Sep 19 2013 Kevin Fenzi <kevin@scrye.com> 1.3.2-1
- Update to 1.3.2 with minor upstream fixes

* Mon Sep 16 2013 Kevin Fenzi <kevin@scrye.com> 1.3.1-1
- Update to 1.3.1

* Sat Sep 14 2013 Kevin Fenzi <kevin@scrye.com> 1.3.0-2
- Merge upstream spec changes to support EPEL5
- (Still needs python26-keyczar and deps added to EPEL)

* Thu Sep 12 2013 Kevin Fenzi <kevin@scrye.com> 1.3.0-1
- Update to 1.3.0
- Drop node-fireball subpackage entirely.
- Obsolete/provide fireball subpackage. 
- Add Requires python-keyczar on main package for accelerated mode.

* Wed Aug 21 2013 Kevin Fenzi <kevin@scrye.com> 1.2.3-2
- Update to 1.2.3
- Fixes CVE-2013-4260 and CVE-2013-4259

* Sat Aug 03 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 1.2.2-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_20_Mass_Rebuild

* Sat Jul 06 2013 Kevin Fenzi <kevin@scrye.com> 1.2.2-1
- Update to 1.2.2 with minor fixes

* Fri Jul 05 2013 Kevin Fenzi <kevin@scrye.com> 1.2.1-2
- Update to newer upstream re-release to fix a syntax error

* Thu Jul 04 2013 Kevin Fenzi <kevin@scrye.com> 1.2.1-1
- Update to 1.2.1
- Fixes CVE-2013-2233

* Mon Jun 10 2013 Kevin Fenzi <kevin@scrye.com> 1.2-1
- Update to 1.2

* Tue Apr 02 2013 Kevin Fenzi <kevin@scrye.com> 1.1-1
- Update to 1.1

* Mon Mar 18 2013 Kevin Fenzi <kevin@scrye.com> 1.0-1
- Update to 1.0

* Wed Feb 13 2013 Fedora Release Engineering <rel-eng@lists.fedoraproject.org> - 0.9-2
- Rebuilt for https://fedoraproject.org/wiki/Fedora_19_Mass_Rebuild

* Fri Nov 30 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.9-0
- Release 0.9

* Fri Oct 19 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.8-0
- Release of 0.8

* Thu Aug 9 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.7-0
- Release of 0.7

* Mon Aug 6 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.6-0
- Release of 0.6

* Wed Jul 4 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.5-0
- Release of 0.5

* Wed May 23 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.4-0
- Release of 0.4

* Mon Apr 23 2012 Michael DeHaan <michael.dehaan@gmail.com> - 0.3-1
- Release of 0.3

* Tue Apr  3 2012 John Eckersberg <jeckersb@redhat.com> - 0.0.2-1
- Release of 0.0.2

* Sat Mar 10 2012  <tbielawa@redhat.com> - 0.0.1-1
- Release of 0.0.1
