# Samba SYSVOL Replication with lsyncd

Near-real-time SYSVOL replication for Samba Active Directory using lsyncd and rsync on Debian 12.

## Overview

This project provides a practical alternative to DFS-R for Samba Active Directory environments. In Microsoft Active Directory, SYSVOL, which contains Group Policy Objects (GPOs), logon scripts and other domain-wide policy files, is typically replicated automatically using DFS-R. Samba Active Directory does not currently provide built-in DFS-R replication, so administrators must implement their own mechanism to keep SYSVOL consistent across domain controllers.



With this solution, changes made to SYSVOL on the authoritative domain controller are replicated automatically to secondary domain controllers within seconds using `lsyncd` and `rsync`. A nightly reconciliation cron job provides an additional safety net.

## Tested Environment

* Domain: `mybranch.mycompany.com`  
* Authoritative domain controller (AD DC) and SYSVOL source: `ad1`
* Replica domain controllers:

  * `ad2`
  * `ad3`
* Operating system: Debian 12
* Samba Active Directory
* `lsyncd`
* `rsync`
* SSH key authentication
* Restricted passwordless `sudo` for `rsync`

## Architecture

```text
ad1 (authoritative SYSVOL source)
  └─ lsyncd monitors:
     /var/lib/samba/sysvol/mybranch.mycompany.com/
        └─ rsync over SSH
           ├─ ad2
           └─ ad3

Nightly cron job:
  /usr/local/sbin/sysvol-sync.sh
  runs at 02:15
```

## Features

* Near-real-time replication (typically within seconds)
* Automatic propagation of file creation, modification, and deletion
* Nightly full reconciliation
* Restricted `sudo` for security
* Tested in a live production environment

## Repository Contents

* `README.md`
* `lsyncd.conf.lua`
* `sysvol-sync.sh`
* `sudoers/sysvol-lsyncd-rsync`
* `docs/test-procedure.md`
* `docs/troubleshooting.md`

## Test Results

The following operations were verified successfully:

* File creation
* File modification
* File deletion
* Automatic replication to both secondary domain controllers

## Operational Model

* All SYSVOL changes are made on `ad1`.
* `lsyncd` detects changes and replicates them automatically.
* The nightly reconciliation job ensures consistency.
* `ad2` and `ad3` are treated as read-only replicas for SYSVOL content.

## Attribution

This solution was developed with substantial assistance from OpenAI's ChatGPT and validated step-by-step in a live Samba Active Directory environment by the author.

## License

\## License



This project is licensed under the MIT License. See the `LICENSE` file for details.

