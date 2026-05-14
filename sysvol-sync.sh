#!/bin/bash
set -euo pipefail

LOG="/var/log/sysvol-sync.log"
SRC="/var/lib/samba/sysvol/mybranch.mycompany.com/"
KEY="/home/happychappie/.ssh/id_ed25519_sysvol_sync"

{
  echo "===== SYSVOL sync started: $(date -Is) ====="

  rsync -aHAX --delete -e "ssh -i ${KEY}" \
    "${SRC}" \
    happychappie@ad2:/tmp/sysvol-mybranch.mycompany.com/

  ssh -i "${KEY}" happychappie@ad2 \
    "sudo rsync -aHAX --delete /tmp/sysvol-mybranch.mycompany.com/ /var/lib/samba/sysvol/mybranch.mycompany.com/"

  rsync -aHAX --delete -e "ssh -i ${KEY}" \
    "${SRC}" \
    happychappie@ad3:/tmp/sysvol-mybranch.mycompany.com/

  ssh -i "${KEY}" happychappie@ad3 \
    "sudo rsync -aHAX --delete /tmp/sysvol-mybranch.mycompany.com/ /var/lib/samba/sysvol/mybranch.mycompany.com/"

  echo "===== SYSVOL sync completed: $(date -Is) ====="
  echo
} >> "${LOG}" 2>&1