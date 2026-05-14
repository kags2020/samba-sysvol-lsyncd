# Troubleshooting Guide

This document covers common issues encountered when implementing SYSVOL replication with `lsyncd` and `rsync`.

## Log Files

### On `ad1`

* `/var/log/lsyncd.log`
* `/var/log/lsyncd-status.log`
* `/var/log/sysvol-sync.log`

### System Logs

```bash
journalctl -u lsyncd -n 50 --no-pager
```

## SSH Connectivity Problems

### Test SSH Access

Run on `ad1`:

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 hostname
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad3 hostname
```

### Common Causes

* Public key not installed.
* Incorrect private key path.
* Wrong permissions on `~/.ssh`.
* SSH host key mismatch.

### Reset Known Host Entries

```bash
ssh-keygen -R ad2
ssh-keygen -R ad3
```

## sudo Permission Problems

### Test Passwordless sudo

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 "sudo rsync --version"
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad3 "sudo rsync --version"
```

### Expected Result

```text
rsync --version should display without prompting for a password.
```

### Verify sudoers Rule

```bash
sudo cat /etc/sudoers.d/sysvol-lsyncd-rsync
```

Expected contents:

```sudoers
happychappie ALL=(root) NOPASSWD: /usr/bin/rsync
```

### Validate sudoers Syntax

```bash
sudo visudo -cf /etc/sudoers.d/sysvol-lsyncd-rsync
```

## lsyncd Will Not Start

### Check Service Status

```bash
systemctl status lsyncd
```

### Validate Configuration

```bash
sudo lsyncd -nodaemon -log all /etc/lsyncd/lsyncd.conf.lua
```

### Common Causes

* Syntax errors in `lsyncd.conf.lua`.
* Incorrect SSH key path.
* SSH authentication failures.
* Missing package dependencies.

## Changes Not Replicating

### Check lsyncd Log

```bash
sudo tail -50 /var/log/lsyncd.log
```

### Confirm Service Running

```bash
systemctl is-active lsyncd
```

### Test Manual Synchronization

```bash
sudo /usr/local/sbin/sysvol-sync.sh
```

## Cron Job Not Running

### Verify Cron Entry

```bash
sudo crontab -l
```

Expected entry:

```cron
15 2 * * * /usr/local/sbin/sysvol-sync.sh
```

### Check Cron Log

```bash
sudo tail -50 /var/log/sysvol-sync.log
```

## Files Exist but Contents Differ

Run on each domain controller:

```bash
sudo find /var/lib/samba/sysvol/mybranch.mycompany.com/ -type f | sort
```

If the file lists match but contents differ, compare checksums:

```bash
cd /var/lib/samba/sysvol/mybranch.mycompany.com/
sudo find . -type f -exec sha256sum {} \; | sort
```

## Permission Problems in SYSVOL

### Test rsync Preservation

```bash
sudo rsync -aHAX --delete source/ destination/
```

The options:

* `-A` preserve ACLs.
* `-X` preserve extended attributes.
* `-H` preserve hard links.

## SSH Host Key Changed

If a replica domain controller is rebuilt:

```bash
ssh-keygen -R ad2
ssh-keygen -R ad3
```

Then reconnect manually to accept the new host keys.

## Useful Diagnostic Commands

```bash
systemctl status lsyncd
journalctl -u lsyncd -n 50 --no-pager
sudo tail -50 /var/log/lsyncd.log
sudo tail -50 /var/log/sysvol-sync.log
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 hostname
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 "sudo rsync --version"
```

## Last Resort Recovery

Run the nightly reconciliation script manually:

```bash
sudo /usr/local/sbin/sysvol-sync.sh
```

This performs a full synchronization from the authoritative source to all replicas.

## Conclusion

Most issues are caused by one of the following:

* SSH authentication failures.
* Incorrect sudoers configuration.
* Syntax errors in `lsyncd.conf.lua`.
* Cron job misconfiguration.

Always check the logs first.
