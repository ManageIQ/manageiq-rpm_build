#! /bin/sh

# This script builds the PDF version of the PostgreSQL documentation.
#
# In principle we could do this as part of the RPM build, but there are
# good reasons not to:
# 1. The build would take longer and have a larger BuildRequires footprint.
# 2. The generated PDF has timestamps in it, which would inevitably result
#    in multilib conflicts due to slightly different timestamps.
# So instead, we run this manually when rebasing to a new upstream release,
# and treat the resulting PDF as a separate Source file.
#
# You will need to have the docbook packages installed to run this.
# Expect it to take about 20 minutes and use about 160MB of disk.

set -e

# Pass package version (e.g., 9.1.2) as argument
VERSION=$1

test -z "$VERSION" && VERSION=`awk '/^Version:/ { print $2; }' postgresql.spec`

TARGETFILE=postgresql-$VERSION-US.pdf
test -f "$TARGETFILE" && echo "$TARGETFILE exists" && exit 1

echo Building $TARGETFILE ...

# Unpack postgresql

rm -rf postgresql-$VERSION

tar xfj postgresql-$VERSION.tar.bz2

cd postgresql-$VERSION

# Apply any patches that affect the PDF documentation

# patch -p1 < ../xxx.patch

# Configure ...

./configure >/dev/null

# Build the PDF docs

cd doc/src/sgml

make postgres-US.pdf >make.log

mv -f postgres-US.pdf ../../../../$TARGETFILE

# Clean up

cd ../../../..

rm -rf postgresql-$VERSION

exit 0
