# FROM quay.io/centos/centos:stream9
FROM registry.fedoraproject.org/fedora:43

WORKDIR /work

RUN dnf -y install git mock && \
    usermod -a -G mock root  # Add root to the mock group because s390x builds are failing AppArmor when calling PAM
