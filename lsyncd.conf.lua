settings {
    logfile        = "/var/log/lsyncd.log",
    statusFile     = "/var/log/lsyncd-status.log",
    statusInterval = 20,
    nodaemon       = false
}

local source = "/var/lib/samba/sysvol/mybranch.mycompany.com/"
local target = "/var/lib/samba/sysvol/mybranch.mycompany.com/"
local key    = "/home/happychappie/.ssh/id_ed25519_sysvol_sync"

sync {
    default.rsync,
    source = source,
    target = "happychappie@ad2:" .. target,
    delay  = 5,
    rsync  = {
        archive  = true,
        compress = false,
        verbose  = true,
        rsh      = "/usr/bin/ssh -i " .. key,
        _extra   = {
            "-H",
            "-A",
            "-X",
            "--delete",
            "--rsync-path=sudo /usr/bin/rsync"
        }
    }
}

sync {
    default.rsync,
    source = source,
    target = "happychappie@ad3:" .. target,
    delay  = 5,
    rsync  = {
        archive  = true,
        compress = false,
        verbose  = true,
        rsh      = "/usr/bin/ssh -i " .. key,
        _extra   = {
            "-H",
            "-A",
            "-X",
            "--delete",
            "--rsync-path=sudo /usr/bin/rsync"
        }
    }
}