# Test Procedure

This document describes the tests used to validate SYSVOL replication with `lsyncd` and `rsync`.

## Test Environment

* Authoritative domain controller (AD DC) and SYSVOL source: `ad1`
* Replica domain controllers:

  * `ad2`
  * `ad3`
* SYSVOL path:

```text
/var/lib/samba/sysvol/mybranch.mycompany.com/
```

## 1. Check lsyncd Is Running

Run on `ad1`:

```bash
systemctl status lsyncd
```

Check logs:

```bash
sudo tail -50 /var/log/lsyncd.log
```

## 2. Test File Creation

Run on `ad1`:

```bash
sudo touch /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad2`:

```bash
ls -l /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad3`:

```bash
ls -l /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Expected result:

```text
The file exists on ad2 and ad3.
```

## 3. Test File Modification

Run on `ad1`:

```bash
echo "modified $(date -Is)" | sudo tee -a /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad2`:

```bash
cat /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad3`:

```bash
cat /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Expected result:

```text
The modified line appears on ad2 and ad3.
```

## 4. Test File Deletion

Run on `ad1`:

```bash
sudo rm /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad2`:

```bash
ls -l /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Verify on `ad3`:

```bash
ls -l /var/lib/samba/sysvol/mybranch.mycompany.com/lsyncd-create-test.txt
```

Expected result:

```text
No such file or directory
```

## 5. Test Nightly Reconciliation Script Manually

Run on `ad1`:

```bash
sudo /usr/local/sbin/sysvol-sync.sh
```

Check the log:

```bash
sudo tail -50 /var/log/sysvol-sync.log
```

Expected result:

```text
SYSVOL sync completed
```

## 6. Check SYSVOL File Lists

Run on each domain controller:

```bash
sudo find /var/lib/samba/sysvol/mybranch.mycompany.com/ -type f | sort
```

Expected result:

```text
The file lists should match across ad1, ad2, and ad3.
```

## 7. Optional Checksum Comparison

For a stronger comparison, run on each domain controller:

```bash
cd /var/lib/samba/sysvol/mybranch.mycompany.com/
sudo find . -type f -exec sha256sum {} \; | sort
```

Expected result:

```text
The checksum lists should match across ad1, ad2, and ad3.
```

## 8. Check Logs After Testing

On `ad1`:

```bash
sudo tail -50 /var/log/lsyncd.log
sudo tail -50 /var/log/sysvol-sync.log
```

## Validation Notes

During initial validation, file creation and deletion were confirmed.

File modification is expected to replicate correctly because `lsyncd` monitors filesystem changes and `rsync` updates changed files, but administrators should explicitly confirm this in their own environment before relying on the solution in production.

## Conclusion

If file creation, modification, deletion, and manual reconciliation all complete successfully, the SYSVOL replication setup is functioning as intended.
