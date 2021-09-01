## Build:

`mock --spec=./manageiq-release.spec -r centos-stream-8-x86_64 --sources=./`

## Sign:

`GNUPGHOME=~/projects/manageiq/gpg_key/ rpmsign --key-id=45C6A67F43428EB5AF03B091119598797762D9B7 --addsign /var/lib/mock/centos-stream-8-x86_64/result/manageiq-release-*.rpm`
