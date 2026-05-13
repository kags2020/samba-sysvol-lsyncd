\# Test Procedure



This document describes the tests used to validate SYSVOL replication.



\## Test Environment



\- Authoritative SYSVOL source: `ad1`

\- Replica domain controllers:

&#x20; - `ad2`

&#x20; - `ad3`

\- SYSVOL path:



```text

/var/lib/samba/sysvol/your.example.local/

1. Check lsyncd Is Running

Run on ad1:

systemctl status lsyncd

Check logs:

sudo tail -50 /var/log/lsyncd.log

2. Test File Creation



Run on ad1:


sudo touch /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad2:

ls -l /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad3:

ls -l /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

3. Test File Modification



Run on ad1:

echo "modified $(date -Is)" | sudo tee -a /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad2:

cat /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad3:

cat /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

4. Test File Deletion

Run on ad1:

sudo rm /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad2:



ls -l /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Verify on ad3:



ls -l /var/lib/samba/sysvol/your.example.local/lsyncd-create-test.txt

Expected result:

No such file or directory

5. Test Nightly Reconciliation Script Manually

Run on ad1:

sudo /usr/local/sbin/sysvol-sync.sh



Check the log:



sudo tail -50 /var/log/sysvol-sync.log

Expected result:



SYSVOL sync completed


6\. Check SYSVOL Consistency


Run on each domain controller:

sudo find /var/lib/samba/sysvol/your.example.local/ -type f | sort

The file lists should match across ad1, ad2, and ad3.


Validation Notes



During initial validation, file creation and deletion were confirmed.



File modification is expected to replicate correctly because lsyncd monitors filesystem changes and rsync updates changed files, but administrators should explicitly confirm this in their own environment.


Then run:



```powershell

git add docs\\test-procedure.md

git commit -m "Add SYSVOL replication test procedure"

git push






















