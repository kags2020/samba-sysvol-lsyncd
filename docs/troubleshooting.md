\# Troubleshooting Guide



This document covers common issues encountered when implementing SYSVOL replication with `lsyncd` and `rsync`.



\## Log Files



\### ad1



\- `/var/log/lsyncd.log`

\- `/var/log/lsyncd-status.log`

\- `/var/log/sysvol-sync.log`



\### System Logs



```bash

journalctl -u lsyncd -n 50 --no-pager

SSH Connectivity Problems

Test SSH Access



Run on ad1:



ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad2 hostname

ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad3 hostname

Common Causes

Public key not installed.

Incorrect private key path.

Wrong permissions on \~/.ssh.

SSH host key mismatch.

Reset Known Host Entry

ssh-keygen -R ad2

ssh-keygen -R ad3

sudo Permission Problems

Test Passwordless sudo

ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad2 "sudo rsync --version"

ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad3 "sudo rsync --version"

Expected Result



rsync --version should display without prompting for a password.



Verify sudoers Rule

sudo cat /etc/sudoers.d/sysvol-lsyncd-rsync



Expected contents:



happychappie ALL=(root) NOPASSWD: /usr/bin/rsync



Validate:



sudo visudo -cf /etc/sudoers.d/sysvol-lsyncd-rsync

lsyncd Will Not Start

Check Service Status

systemctl status lsyncd

Validate Configuration

sudo lsyncd -nodaemon -log all /etc/lsyncd/lsyncd.conf.lua

Common Causes

Syntax errors in the Lua configuration.

Incorrect SSH key path.

SSH authentication failures.

Missing package dependencies.

Changes Not Replicating

Check lsyncd Log

sudo tail -50 /var/log/lsyncd.log

Confirm Service Running

systemctl is-active lsyncd

Test Manual rsync

sudo /usr/local/sbin/sysvol-sync.sh

Cron Job Not Running

Verify Cron Entry

sudo crontab -l



Expected entry:



15 2 \* \* \* /usr/local/sbin/sysvol-sync.sh

Check Log

sudo tail -50 /var/log/sysvol-sync.log

Files Exist but Contents Differ



Run on each domain controller:



sudo find /var/lib/samba/sysvol/your.example.local/ -type f | sort



Compare file lists and checksums if necessary.



Permission Problems in SYSVOL



Run:



sudo rsync -aHAX --delete source/ destination/



The -A and -X options preserve ACLs and extended attributes.



SSH Host Key Changed



If you rebuild a replica DC:



ssh-keygen -R ad2

ssh-keygen -R ad3



Then reconnect manually to accept the new host key.



Useful Diagnostic Commands

systemctl status lsyncd

journalctl -u lsyncd -n 50 --no-pager

sudo tail -50 /var/log/lsyncd.log

sudo tail -50 /var/log/sysvol-sync.log

ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad2 hostname

ssh -i \~/.ssh/id\_ed25519\_sysvol\_sync happychappie@ad2 "sudo rsync --version"

Last Resort Recovery



Run the nightly reconciliation script manually:



sudo /usr/local/sbin/sysvol-sync.sh



This performs a full synchronization from the authoritative source to all replicas.



Conclusion



Most issues are caused by one of the following:



SSH authentication failures.

Incorrect sudoers configuration.

Syntax errors in lsyncd.conf.lua.

Cron job misconfiguration.



Always check the logs first.

