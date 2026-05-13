#!/bin/bash
set -euo pipefail

LOG="/var/log/sysvol-sync.log"
SRC="/var/lib/samba/sysvol/ecs.kinghorndesign.com/"
KEY="/home/kags/.ssh/id_ed25519_sysvol_sync"

{
  echo "===== SYSVOL sync started: $(date -Is) ====="

  rsync -aHAX --delete -e "ssh -i ${KEY}" \
    "${SRC}" \
    kags@ad2:/tmp/sysvol-ecs.kinghorndesign.com/

  ssh -i "${KEY}" kags@ad2 \
    "sudo rsync -aHAX --delete /tmp/sysvol-ecs.kinghorndesign.com/ /var/lib/samba/sysvol/ecs.kinghorndesign.com/"

  rsync -aHAX --delete -e "ssh -i ${KEY}" \
    "${SRC}" \
    kags@ad3:/tmp/sysvol-ecs.kinghorndesign.com/

  ssh -i "${KEY}" kags@ad3 \
    "sudo rsync -aHAX --delete /tmp/sysvol-ecs.kinghorndesign.com/ /var/lib/samba/sysvol/ecs.kinghorndesign.com/"

  echo "===== SYSVOL sync completed: $(date -Is) ====="
  echo
} >> "${LOG}" 2>&1