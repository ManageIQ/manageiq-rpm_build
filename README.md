# ManageIQ RPM Build

This repository contains code to build RPMs for ManageIQ appliances and container images:

  * Clone source repos
  * Run bundle install, compiles assets for UI and a few other tasks needed
  * Create tarballs
  * Optionally build RPMs (currently only Copr is supported)

## Steps

1. Build container image

   If building RPMs in Copr, obtain auth token and copy to `./copr-cli-token` before building the container image.

2. Start container image

   - If overriding npm registry, run container image with `-e NPM_REGISTRY_OVERRIDE='https://path/to/your/npm/registry'`

   - If building RPMs in Copr, run container image with `-e COPR_RPM_BUILD=true`

3. Set options and run the script

   - Modify `config/options.yml` as needed. If building RPMs in Copr, `repo_name` must be set

   - Run `bin/build.rb`, optionally overriding git ref (branch or tag) and release type
     ```
     bin/build.rb --git-ref jansa
     ```
     ```
     bin/build.rb --build-type release --git-ref jansa-1-alpha1
     ```


Alternatively, build can be started by passing 'build' to docker run command:

`docker run -it <miq-rpm_build image> build [--build-type <type>] [--git-ref <ref>]`

The container will exit after build is completed. Use `-v <dir>:/root/BUILD` to mount a volume if artifacts need to be
accessed later.

## Artifacts

manageiq, manageiq-gemset and manageiq-appliance .tar.gz will be created in `~/BUILD/rpm_spec/<rpm name>/` (`~/BUILD` is configurable in options.yml)

## License

This code is available as open source under the terms of the [Apache License 2.0](LICENSE).
