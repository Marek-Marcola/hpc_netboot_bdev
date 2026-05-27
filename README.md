netboot bdev
============

Netboot development tools.

Install
-------
Install required software:

    packer
    qemu-kvm
    ansible
    sshpass
    yq

Install:

    ./bdev.sh --install
    -- or --
    cp -fv bdev.env /usr/local/etc
    cp -fv bdev.sh /usr/local/bin

Postinstall:

    # cat > /etc/profile.d/zlocal-bdev.sh <<\EOF
    b() {
      local desc="@@netboot development (via bdev.sh)@@"
      bdev.sh $@
    }
    EOF

Configure ansible:

    # vi $PB/etc/ansible.cfg
    [ssh_connection]
    scp_if_ssh = true
    scp_extra_args = -O
    ...

Verify:

    bdev.sh --version

Help:

    bdev.sh --help
