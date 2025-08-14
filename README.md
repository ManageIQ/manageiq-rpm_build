# ManageIQ RPM Build

[![CI](https://github.com/ManageIQ/manageiq-rpm_build/actions/workflows/ci.yaml/badge.svg?branch=spassky)](https://github.com/ManageIQ/manageiq-rpm_build/actions/workflows/ci.yaml)

## Summary

This repository contains code to build RPMs for ManageIQ appliances and container images.

It performs the following tasks:

  * Clone source repos
  * Run bundle install, compiles assets for UI and a few other tasks needed
  * Create tarballs
  * Build RPMs (locally in the container image or in Copr)

## Output

It produces the following rpms:

| rpm                        | contents                                                          |
|----------------------------|-------------------------------------------------------------------|
| `manageiq-appliance-tools` | **empty**                                                         |
| `manageiq-gemset`          | `/opt/manageiq/manageiq-gemset/` gems, providers, ui-classic      |
| `manageiq-gemset-services` | `manageiq-provider-*{.target,@.service}`                          |
| `manageiq-core`            | `vmdb/{app,certs,content,lib,product,systemd}`                    |
| `manageiq-core-services`   | `manageiq-*{.target,@.service}`                                   |
| `manageiq-system`          | `/etc/{default,chron}, /usr/bin/evm*, system/{evm,miq}*.service`  |
| `manageiq-appliance`       | `/etc/httpd/conf.d/manageiq-*, /etc/motd.manageiq`                |
| `manageiq-ui`              | `vmdb/public/{assets,packs,ui}`                                   |
| `manageiq-pods`            | **empty**                                                         |

* `/usr/lib/systemd/system/` contains systemd service files.
* `/var/www/miq/vmdb` contains application files.
* `/opt/manageiq/manageiq-appliance` contains files linked into `/etc/`.
* `/opt/manageiq/manifest` contains manifests.

## Steps

## Obtain container image for building RPMs

You can either download the latest build image or building a new one locally:

  - `docker pull manageiq/rpm_build:latest`
  - `docker pull manageiq/rpm_build:latest-jansa`
  - `docker build --pull --tag $USER/rpm_build:latest .`

Typically the first example works best, but if you are modifying which files end up in the rpm, the third example is the one you want.

## Building a release

The github tag/branch is passed on the command line e.g.: `--git-ref jansa`. A few other options and explanations are available in [build.rb](blob/master/bin/build.rb#L8) for the basic installs.


```sh
docker run --rm manageiq/rpm_build:latest build --git-ref lasker --update-rpm-repo
```

For older builds, the `git-ref` is already stored in `config/options.yml` and not necessary.

```sh
docker run --rm manageiq/rpm_build:jansa-3 build --update-rpm-repo
```

## Building a custom release

Sometimes it is necessary to build rpms with code from pull requests. This explains how to do that.

### Defining build parameters

The [options.yml](blob/master/config/options.yml) points to the appropriate repos and tag/branches.

A typical `options.yml` will only override the source and the refs. This example uses branch `feature1` from kbrock's github repo:

```sh
mkdir OPTIONS
vi OPTIONS/options.yml
```

```yaml
---
product_name:      manageiq
repos:
  ref:             master
  manageiq:
    url:           https://github.com/kbrock/manageiq.git
    ref:           feature1
  manageiq_appliance:
    url:           https://github.com/kbrock/manageiq-appliance.git
    ref:           feature1
```

The option file is brought into docker by mounting the directory with `-v $(pwd)/OPTIONS:/root/OPTIONS`

### Using a custom NPM registry

Any of the keys in [options.yml](blob/master/config/options.yml) can be overridden.

   - If overriding the NPM registry, set the `npm_registry` key in the `options.yml`.
   - If building RPMs in Copr,
     - set the `rpm.repo_name` key in the `options.yml`.
     - run the container image with `-v <copr token file>:/root/.config/copr`.
   - If updating the RPM repo it would be helpful to attach a volume to hold the RPM cache with `-v <dir>:/root/rpm_cache`.
     Any RPMs not in the cache will be downloaded to the cache first.

### Artifacts

The purpose of this process is to build code from `manageiq-core`, `manageiq-gemset`, and `manageiq-appliance` into 2 sets of artifacts:

- `/root/BUILD/rpm_spec/*.tar.gz`
- `/root/BUILD/rpms/x86_64/manageiq-*.rpm`

One approach is to build and mount a volume that will receive all artifacts:

```sh
docker run --rm -v `pwd`/OPTIONS:/root/OPTIONS -v `pwd`/BUILD:/root/BUILD manageiq/rpm_build:latest build
```

Another approach is to build and copy out the desired artifacts:

```sh
CONTAINER='my-build-container'
docker run --name ${CONTAINER} -v `pwd`/OPTIONS:/root/OPTIONS manageiq/rpm_build:latest build
docker cp ${CONTAINER}:/root/BUILD/rpms/x86_64/ ./rpms/
docker rm ${CONTAINER}
```

## Building a Hotfix

Sometimes it is necessary to apply a patch without rebuilding the whole release in order to
deliver a fix quickly.  This can be accomplished by building a hotfix rpm which will apply
a series of patches.

Create a patch file using `git format-patch` and copy to `rpm_spec/patches/`.  You will have to modify the path to be relative to the RPM BUILDDIR.

For example if we wanted to create a hotfix to apply a commit in radjabov `1286aa34992340cad7a0778df01a845f1772e561` we would run:
```sh
git format-patch -1 1286aa34992340cad7a0778df01a845f1772e561
```

Which will create a patch file: `0001-Merge-pull-request-23123-from-agrare-fix_miq_request.patch`

Make sure to remove any changes to spec files, as these are not packaged with the RPMs and will cause a conflict when
the patch is applied.

Next we have to change the file location to match the RPM BUILDDIR, for a patch in the core rpm this will be e.g. `manageiq-core-18.0-1`

```
diff --git a/manageiq-core-18.0-1/app/models/miq_provision_request_template.rb b/manageiq-core-18.0-1/app/models/miq_provision_request_template.rb
index 621f20b7e7..f62f454ac5 100644
--- a/manageiq-core-18.0-1/app/models/miq_provision_request_template.rb
+++ b/manageiq-core-18.0-1/app/models/miq_provision_request_template.rb
```

This ensures that the hotfix patch will apply correctly when it is run.  Then move that patch
file to `rpm_spec/patches/` in the rpm_build repo.

`docker build --pull --tag $USER/rpm_build:radjabov-hotfix .`

Create a `BUILD/hotfix` directory and copy the .src.rpm for the release that you want to
build a hotfix against, for example `manageiq-release-18.0-1.el9.src.rpm`

```sh
docker run --rm -v `pwd`/OPTIONS:/root/OPTIONS -v `pwd`/BUILD:/root/BUILD $USER/rpm_build:radjabov-hotfix build_hotfix
```

The rpms for the hotfix will be in `BUILD/rpms`.

## Versioning

Branch `morphy` == v13

| Version               | Purpose     | Repo    |
|-----------------------|-------------|---------|
| 13.0.0-20210708000051 | nightly     | nightly |
| 13.0.1-beta1          | pre-release | release |
| 13.0.1-20210708000051 | nightly     | nightly |
| 13.0.2-rc1            | pre-release | release |
| 13.1.0-0              | release     | release |
| 13.1.0-20210708000051 | nightly     | nightly |
| 13.2.0-0              | release     | release |
| 13.2.0-20210708000051 | nightly     | nightly |

## License

This code is available as open source under the terms of the [Apache License 2.0](LICENSE.txt).
