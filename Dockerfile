#
# Dockerfile for Minidump receiver 
#
# Receives minidumps by SFTP.
# Stores received files to /sftp/minidumps/incoming
# Archiving and cleanup done externally by user 'archiver'.
#
# Ports
#  22 (ssh)
#
# Users
#  archiver:archiver
#  minidumps:sftpusers
#
# Archiver Authenication
#  [@repo]/authorized_keys
#
# SFTP Client Authentication
#  username: minidumps
#  password: minidumps
#  key: not_impl (password only)
#
# SFTP Config
#  [@repo]/sshd_config
#
# Other Notes
#  Minidumps should be uniquely named by the client (GUID based).
#  Minidumps should be encrypted with archiver's pubkey by client or on server after upload
#   Because minidumps user may have read access to other minidumps, before they are archived
#
FROM ubuntu:latest

# install tzdata, then OpenSSH (for SFTP)
RUN apt-get update &&\    
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends &&\
    apt-get install ssh -y

# add archiver user to manage and pull/archive received dumps
RUN addgroup archiver &&\
    useradd -rm archiver -s /bin/bash -g archiver &&\
    usermod -p '*' archiver

# add minidumps user (SFTP access only, no shell)
RUN addgroup sftpusers &&\
    useradd -m minidumps -g sftpusers &&\
    echo 'minidumps:minidumps' | chpasswd

# create directory for SFTP uploads, set permissions
RUN mkdir -p /sftp/minidumps/incoming &&\
    chown minidumps:sftpusers /sftp/minidumps/incoming

# copy sshd_config from repo
COPY sshd_config /etc/ssh/sshd_config

# copy authorized_keys pubkey for archiver (do not use for client uploads!)
COPY authorized_keys /home/archiver/.ssh/authorized_keys
RUN chown archiver:archiver /home/archiver/.ssh/authorized_keys

# start sshd, keep shell running
CMD service ssh start && /bin/bash