netboot bdev
============

HPC netboot development tools.

Install
-------
Install required software:

    packer
    qemu-kvm
    ansible
    sshpass
    yq

Install:

    bdev.sh --inst -x
    -- or --
    bdev.sh --anpb -x
    -- or --
    cp -fv bdev.sh /usr/local/bin
    cp -fv bdev.env /usr/local/etc
    cp -fv zlocal-bdev.sh /etc/profile.d

Configure ansible:

    # vi $PB/etc/ansible.cfg
    [ssh_connection]
    scp_if_ssh = true
    scp_extra_args = -O
    ...

Verify:

    b -ver

Help:

    b -h
