# Installation Guide

This document describes how to implement near-real-time SYSVOL replication for Samba Active Directory using `lsyncd` and `rsync` on Debian 12.

---

## Attribution

This solution was developed with substantial assistance from OpenAI's ChatGPT and validated step-by-step in a live Samba Active Directory environment by the author.

---

## 1. Overview

Samba Active Directory does not provide DFS-R replication for SYSVOL.

This solution uses:

- `lsyncd` for near-real-time replication
- `rsync` over SSH
- Restricted passwordless `sudo` on replica DCs
- A nightly reconciliation script as a safety net

### Architecture

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

---

## 2. Tested Environment

- Domain: `mybranch.mycompany.com`
- Authoritative SYSVOL source: `ad1`
- Replica DCs: `ad2`, `ad3`
- Operating system: Debian 12
- Samba Active Directory
- `lsyncd`
- `rsync`
- SSH key authentication
- Restricted passwordless `sudo`

---

## 3. Operational Model

- All SYSVOL changes are made only on `ad1`.
- `ad2` and `ad3` are treated as read-only replicas.
- `lsyncd` propagates changes within seconds.
- A nightly `rsync` reconciliation ensures consistency.

---

## 4. Install Required Packages

Run on **ad1**.

```bash
sudo apt update
sudo apt install -y lsyncd rsync
```

Run on **ad2** and **ad3**.

```bash
sudo apt update
sudo apt install -y rsync
```

---

## 5. Create SSH Key on ad1

Run on **ad1**.

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_sysvol_sync -C "sysvol-sync"
```

Press Enter to accept an empty passphrase.

---

## 6. Install Public Key on Replica DCs

Run on **ad1**.

```bash
ssh-copy-id -i ~/.ssh/id_ed25519_sysvol_sync.pub happychappie@ad2
ssh-copy-id -i ~/.ssh/id_ed25519_sysvol_sync.pub happychappie@ad3
```

Verify:

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 hostname
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad3 hostname
```

---

## 7. Configure Passwordless sudo on Replica DCs

Create the sudoers file on **ad2** and **ad3**.

```bash
sudo visudo -f /etc/sudoers.d/sysvol-lsyncd-rsync
```

Contents:

```sudoers
happychappie ALL=(root) NOPASSWD: /usr/bin/rsync
```

Set permissions:

```bash
sudo chmod 0440 /etc/sudoers.d/sysvol-lsyncd-rsync
```

Validate:

```bash
sudo visudo -cf /etc/sudoers.d/sysvol-lsyncd-rsync
```

Test from **ad1**:

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 "sudo rsync --version"
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad3 "sudo rsync --version"
```

---

## 8. Install `lsyncd.conf.lua` on ad1

Copy the repository file to:

```text
/etc/lsyncd/lsyncd.conf.lua
```

Create a backup first:

```bash
sudo cp -a /etc/lsyncd/lsyncd.conf.lua /etc/lsyncd/lsyncd.conf.lua.bak 2>/dev/null || true
```

Then edit:

```bash
sudo nano /etc/lsyncd/lsyncd.conf.lua
```

Use the repository version of `lsyncd.conf.lua`.

---

## 9. Validate lsyncd Configuration

Run on **ad1**.

```bash
sudo lsyncd -nodaemon -log all /etc/lsyncd/lsyncd.conf.lua
```

If no errors appear, stop with `Ctrl+C`.

---

## 10. Enable and Start lsyncd

Run on **ad1**.

```bash
sudo systemctl enable lsyncd
sudo systemctl restart lsyncd
sudo systemctl status lsyncd
```

Check logs:

```bash
sudo tail -f /var/log/lsyncd.log
```

---

## 11. Install Nightly Reconciliation Script

Copy the repository file to:

```text
/usr/local/sbin/sysvol-sync.sh
```

Create a backup if the file exists:

```bash
sudo cp -a /usr/local/sbin/sysvol-sync.sh /usr/local/sbin/sysvol-sync.sh.bak 2>/dev/null || true
```

Edit:

```bash
sudo nano /usr/local/sbin/sysvol-sync.sh
```

Set permissions:

```bash
sudo chmod 0755 /usr/local/sbin/sysvol-sync.sh
```

Test manually:

```bash
sudo /usr/local/sbin/sysvol-sync.sh
```

Check the log:

```bash
sudo tail -50 /var/log/sysvol-sync.log
```

---

## 12. Create Cron Job

Run on **ad1**.

```bash
sudo crontab -e
```

Add:

```cron
15 2 * * * /usr/local/sbin/sysvol-sync.sh
```

Verify:

```bash
sudo crontab -l
```

---

## 13. Functional Testing

### Create Test File

Run on **ad1**.

```bash
sudo touch /var/lib/samba/sysvol/mybranch.mycompany.com/test-file.txt
```

Verify on **ad2** and **ad3**.

```bash
ls -l /var/lib/samba/sysvol/mybranch.mycompany.com/test-file.txt
```

### Modify Test File

```bash
echo "test $(date)" | sudo tee -a /var/lib/samba/sysvol/mybranch.mycompany.com/test-file.txt
```

### Delete Test File

```bash
sudo rm /var/lib/samba/sysvol/mybranch.mycompany.com/test-file.txt
```

Verify deletion on `ad2` and `ad3`.

---

## 14. Monitor Replication

On **ad1**:

```bash
sudo tail -f /var/log/lsyncd.log
```

Check service status:

```bash
systemctl status lsyncd
```

---

## 15. Troubleshooting

### SSH Authentication Failure

Test:

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 hostname
```

### sudo Failure

Test:

```bash
ssh -i ~/.ssh/id_ed25519_sysvol_sync happychappie@ad2 "sudo rsync --version"
```

### lsyncd Configuration Errors

Validate:

```bash
sudo lsyncd -nodaemon -log all /etc/lsyncd/lsyncd.conf.lua
```

### Log Files

- `/var/log/lsyncd.log`
- `/var/log/lsyncd-status.log`
- `/var/log/sysvol-sync.log`

---

## 16. Security Notes

- Restrict write access to SYSVOL to `ad1` only.
- Use a dedicated SSH key for replication.
- Restrict passwordless `sudo` to `/usr/bin/rsync` only.
- Monitor logs regularly.

---

## 17. Repository Files

- `README.md`
- `lsyncd.conf.lua`
- `sysvol-sync.sh`
- `sudoers/sysvol-lsyncd-rsync`
- `docs/installation.md`
- `docs/test-procedure.md`
- `docs/troubleshooting.md`

---

## 18. Validation Results

This solution was tested successfully in production.

Verified operations:

- File creation
- File deletion
- Automatic replication to both replica domain controllers

Expected behaviour (not explicitly tested during the initial validation):

- File modification should replicate correctly when file contents, size, or modification time change, as this is standard `lsyncd`/`rsync` behaviour.
- Administrators are encouraged to perform a simple modification test in their own environment before relying on the solution in production.
- Nightly reconciliation

---

## 19. Updating the Repository

After editing any file locally:

```bash
git add .
git commit -m "Describe the change"
git push
```

---

## 20. Conclusion

This approach provides a practical and robust replacement for DFS-R in Samba Active Directory environments using standard Linux tools.

