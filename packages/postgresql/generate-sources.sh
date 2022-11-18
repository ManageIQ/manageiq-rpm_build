#! /bin/sh

rm sources
set -e
spectool -S *.spec | cut -d' ' -f2 \
    | grep -E -e 'postgresql-.*\.tar\.*' -e 'postgresql.*\.pdf' | sort | \
while read line
do
    base=`basename "$line"`
    echo " * handling $base"
    sha512sum --tag "$base" >> sources
done
