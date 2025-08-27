# Driver updates and you

Driver updates provide a way to update kernel drivers and to influence the
installation workflow **during the installation** of SUSE Linux.
Kernel modules on the running system are updated with the usual update process (of the kernel rpm).

They are described in the [Update Media Howto](http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/Update-Media-HOWTO.html)

A driver update can be either an archive file or a directory (the unpacked archive).


## Use driver updates

1. Use the `inst.dud` (Agama) or `dud` (YaST) boot option to pass a URL pointing to the driver update. For example:

    - `inst.dud=https://example.com/foo.dud`
    - `dud=disk:/foo.dud`

2. Driver updates in special places are loaded automatically:

    - a file named `driverupdate` in the root directory of the installation medium (YaST only)
    - a partition (e.g. on a USB stick) with file system label `OEMDRV` containing an unpacked driver update (YaST only)
    - an unpacked driver update in the initrd of the installation medium

3. Apply the driver update directly to the installation medium

For supported URL schemas look at

- https://agama-project.github.io/docs/user/reference/boot_options (Agama)
- https://en.opensuse.org/SDB:Linuxrc (YaST)

Putting the driver update into the initrd provides a way to seamlessly integrate driver updates into otherwise
unchanged SUSE installation media. The `mkmedia` command has a dedicated `--initrd` option to make this easy:

```sh
mkmedia --create new.iso --initrd foo.dud old.iso
```

To make changes that are otherwise technically not possible - like modifying the initrd or changing boot options you
have to use the `--apply-dud` option of `mkmedia` to modify the installation medium directly:

```sh
mkmedia --create new.iso --apply-dud foo.dud old.iso
```

The difference between `--initrd` and `--apply-dud` is that the first makes the DUD available during installation
(without any user-interaction) while the second interpretes the DUD and applies the changes it describes to the
installation medium.

`mkmedia` is part of the [mksusecd](https://github.com/openSUSE/mksusecd) package.

## Create driver updates

To create driver updates use `mkdud`. You have to specify at least the product the driver update is intended for but it's
also nice to give it a descriptive name:

```sh
mkdud --create foo.dud --dist leap15.6 --name "Support the new bar" bar.ko
```

Driver updates have to be properly signed to be accepted by the installer. If they are not the user will
see a dialog asking them for manual confirmation during the installation process.

The signature can be detached (e.g. `foo.dud.asc` for `foo.dud`) or integrated. It's possible to use `mkdud --[detached-]sign` for this.
But typically some external infrastructure for signing is used.

An interesting alternative is to use signed rpms for driver updates. This way you can get properly signed driver updates
out of the [openSUSE Build Service](https://build.opensuse.org) for example.


## Update and load kernel modules

To create a driver update that updates kernel modules `bar.ko` and `foo.ko` for product `xxx`:

```sh
mkdud --create foobar.dud --dist xxx bar.ko foo.ko
```

Note that you have to take module dependencies into account (they are not resolved automatically).

Sometimes modules must be loaded in a specific order. For this, add a file `module.order` containing one module name (without `.ko`) per line:

```sh
echo -e "foo\nbar" >module.order
mkdud --create foobar.dud --dist xxx bar.ko foo.ko module.order
```

If you have to prevent a (broken) kernel module to be loaded in the first
place tell the user to add `brokenmodules=foo` to the boot options. In the driver update that
provides a fixed version of `foo.ko` it is usually a good idea to remove this restriction so the module
will no get blocked in the target system. For this you can add a `brokenmodules` option to the driver update:

```sh
mkdud --create foo.dud --dist xxx --config "brokenmodules=-foo" foo.ko
```


## Update and load kernel modules with module parameters

If you have to load an updated kernel module with additional module parameters you can use the `options` config option.
For example:

```sh
mkdud --create foo.dud --dist xxx --config "options=foo.foo_option=1" foo.ko
```

will load `foo.ko` with `foo_option=1`.


## Set config (boot) options

As shown in the examples above driver updates can also set boot options to influence the installation. For example:

```sh
mkdud --create foo.dud --dist xxx --config "autoyast=https://example.com/foo.xml" --config "selfupdate=0"
```

Even loading further driver updates is possible:

```sh
mkdud --create foo.dud --dist xxx --config "dud=https://example.com/bar.dud"
```


## Update the installation system

You can also replace or add any file in the installation system. For this, create a directory structure and put the file into it.
For example, this will add the content of the `/tmp/foo` directory to the installation system:

```sh
mkdir -p /tmp/foo/usr/bin
cp /usr/bin/cat /tmp/foo/usr/bin
mkdud --create foo.dud --dist xxx --name "Replace cat" /tmp/foo
```

For an easier way to update complete packages see the next section.


## Update packages

Packages might be updated in the installation system (when needed during installation) and in the target system (if they
are needed also later). Here's an example:

```sh
mkdud --create foo.dud --dist xxx foo.rpm
```

This replaces `foo.rpm` in the installation system **and** the target system. The update in the target system is done
by creating a temporary add-on repository and adding the packages there. The repositories show up as `DriverUpdateX` in
the installer's package manager.

You can fine-tune package updates with `mkdud`'s `--install` option. For example, to only update the installation system, not the
target system:

```sh
mkdud --create foo.dud --dist xxx --install instsys foo.rpm
```


## Adjust installation workflow (YaST only)

Driver updates also prove hooks into the installation workflow. This is done by triggering shell scripts at specific points. They are

- `update.pre`: right before yast will be started
- `update.post`: after packages have been installed
- `update.post2`: after everything has been done, right before the target system will be unmounted and rebooted

Simply pass the scripts with the above exact names to `mkdud`:

```sh
echo "systemctl enable foo" > update.post2
mkdud --create foo.dud --dist xxx update.post2
```

to enable the `foo` service.


## Execute commands (YaST only)

Sometimes the commands in `update.pre` are run too late for your purpose. It is possible to run commands immediately (when the driver update has
been loaded). For this, the `exec` config option can be used. For example

```sh
mkdud --create foo.dud --dist xxx --config "exec=rmmod foo"
```

would unload module `foo` immediately.


## Combine driver updates

A driver update is not limited to a single action. You can specify all the described things in a single command line, repeating `mkdud` options
as needed.

But if you are handed a number of driver updates and have to apply them all you might simplify things by combining them into a
single driver update:

```sh
mkdud --create all.dud foo.dud bar.dud zap.dud
```

## Examples

Let's look at a few basic examples.

### Example 1

```
# mkdud --create foo.dud --dist sle16 --name "Test update" \
  hello.rpm e1000.ko.xz
===  Update #1  ===
  [SUSE Linux Enterprise 16 (x86_64)]
    Name:
      Test update
    ID:
      3c39839e-bf42-49ee-a405-6f97c0732a9f
    Installer:
      Agama
    Packages:
      - install methods: instsys, repo
      hello-2.12.2-1.5.x86_64.rpm  (Mon May 19 19:43:32 2025)
    Modules:
      e1000.ko.xz (6.12.0-160000.18-default.x86_64)
    Installation System:
      - package: hello-2.12.2-1.5.x86_64.rpm
      /usr/bin/hello
    How to apply this DUD:
      [✔] during installation: using boot option inst.dud=URL_TO_DUD_FILE
      [✘] during installation: unpacked on local file system with label 'OEMDRV'
      [✘] during installation: renamed as 'driverupdate' in installation repository
      [✔] rebuilding installation media using 'mkmedia --initrd DUD_FILE ...'
      [✔] rebuilding installation media using 'mkmedia --apply-dud DUD_FILE ...'
```

This DUD

- is intended for Agama (SLE 16)
- updates the `hello` package in the installed (target) system
- adds the `hello` package to the installation system
- updates the `e1000` kernel module

Note that in Agama-based installations the 'OEMDRV' and 'driverupdate' methods are not available.

### Example 2

```
# mkdud --create foo.dud --dist tw --name "Test update" \
  hello.rpm e1000.ko.xz \
  --config password=xxx
===  Update #1  ===
  [openSUSE Tumbleweed (x86_64)]
    Name:
      Test update
    ID:
      2deb1bab-d22d-4f93-9574-77905456eaf8
    Installer:
      YaST
    Packages:
      - install methods: instsys, repo, rpm (repo priority 50)
      hello-2.12.2-1.5.x86_64.rpm  (Mon May 19 19:43:32 2025)
    Modules:
      e1000.ko.xz (6.12.0-160000.18-default.x86_64)
    Scripts:
      update.pre, update.post2
    Installation System:
      - package: hello-2.12.2-1.5.x86_64.rpm
      /usr/bin/hello
    Config Entries:
      password = xxx
    How to apply this DUD:
      [✔] during installation: using boot option dud=URL_TO_DUD_FILE
      [✔] during installation: unpacked on local file system with label 'OEMDRV'
      [✔] during installation: renamed as 'driverupdate' in installation repository
      [✔] rebuilding installation media using 'mkmedia --initrd DUD_FILE ...'
      [✔] rebuilding installation media using 'mkmedia --apply-dud DUD_FILE ...'
```

This DUD

- is intended for YaST (Tumbleweed)
- updates the `hello` package in the installed (target) system
- adds the `hello` package to the installation system
- updates the `e1000` kernel module
- sets the root password used in the installation system (e.g. for ssh access)

Since in YaST-based installations config setting are possible, the DUD can be applied by any method.

Note that `mkdud` automatically generates `update.pre` and `update.post2` scripts that handle adding and removing a
driver update software repository (needed for 'repo' install method) during installation.

### Example 3

```
# mkdud --create foo.dud --dist leap16.0 --name "Test update" \
  --initrd hello.rpm \
  e1000.ko.xz \
  --config live.password=xxx --config boot=nomodeset
===  Update #1  ===
  [openSUSE Leap 16.0 (x86_64)]
    Name:
      Test update
    ID:
      45f627da-b7c4-48ed-94c1-31e25ed92442
    Installer:
      YaST
    Modules:
      e1000.ko.xz (6.12.0-160000.18-default.x86_64)
    Initrd:
      - package: hello-2.12.2-1.5.x86_64.rpm
      /usr/bin/hello
    Config Entries:
      live.password = xxx
    Boot Options:
      nomodeset
    How to apply this DUD:
      [✘] during installation: using boot option dud=URL_TO_DUD_FILE
      [✘] during installation: unpacked on local file system with label 'OEMDRV'
      [✘] during installation: renamed as 'driverupdate' in installation repository
      [✘] rebuilding installation media using 'mkmedia --initrd DUD_FILE ...'
      [✔] rebuilding installation media using 'mkmedia --apply-dud DUD_FILE ...'
```

This DUD

- is intended for Agama (Leap 16.0)
- adds the `hello` package to the initrd
- updates the `e1000` kernel module
- sets the root password used in the installation system (note the different option compared to the last example)
- sets boot option `nomodeset`

Since boot options can not be changed during an installation (it is too late), the
DUD can only be applied by modifying the installation medium.



## Troubleshooting (YaST-based installations)

Sometimes things just don't work as expected. Here is a detailed guide that walks you through the entire update process
and shows what exactly to expect.

For illustrating purposes a driver update for [libparted0](https://software.opensuse.org/package/libparted0)
(the library containing the core functionality of [parted](https://software.opensuse.org/package/parted)) is used.

The latest version of libpart0 is (at the time I'm writing this) contained in package `libparted0-3.3-1.1.x86_64.rpm`.

One last note before we start:

- 'installation system' refers to the small system the installer runs in during the installation
- 'target system' refers to the system that gets finally installed

### Creating the driver update

Let's make a driver update for Tumbleweed of our package:

```sh
> mkdud --create foo.dud --dist tw libparted0-3.3-1.1.x86_64.rpm
===  Update #1  ===
  [openSUSE Tumbleweed (x86_64)]
    Name:
      libparted0-3.3-1.1.x86_64 Wed Jan 15 15:33:15 2020
    ID:
      c599d3ac-9bf7-48cb-b593-bd6612388049
    Packages:
      libparted0-3.3-1.1.x86_64.rpm  (Wed Jan 15 15:33:15 2020)
      - install methods: instsys, repo, rpm (repo priority 50)
    Scripts:
      update.pre, update.post2
    Installation System:
      /usr/lib64/libparted-fs-resize.so.0.0.2
      /usr/lib64/libparted.so.2.0.2
```

You can use `mkdud --show foo.dud` to get the same overview of what's inside the driver update.

It is important that the argument to `--dist` is the correct product. Driver updates are always for a specific product.
Use `--dist` several times to make an update that applies to more than one product.

`foo.dud` is a compressed CPIO archive. Looking inside shows this:

```sh
> zcat foo.dud | cpio -tv
drwxr-xr-x   1 root     root            0 Mar  4 12:12 .
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse/x86_64-tw
-rw-r--r--   1 root     root          134 Mar  4 12:12 linux/suse/x86_64-tw/dud.config
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse/x86_64-tw/install
-r--r--r--   1 root     root       240304 Mar  4 12:12 linux/suse/x86_64-tw/install/libparted0-3.3-1.1.x86_64.rpm
-rwxr-xr-x   1 root     root          191 Mar  4 12:12 linux/suse/x86_64-tw/install/update.post2
-rwxr-xr-x   1 root     root          910 Mar  4 12:12 linux/suse/x86_64-tw/install/update.pre
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys
-rw-r--r--   1 root     root           26 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys/.update.c599d3ac-9bf7-48cb-b593-bd6612388049
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys/usr
drwxr-xr-x   1 root     root            0 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys/usr/lib64
lrwxrwxrwx   1 root     root           28 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys/usr/lib64/libparted-fs-resize.so.0 -> libparted-fs-resize.so.0.0.2
-rwxr-xr-x   1 root     root        88504 Jan 15 16:35 linux/suse/x86_64-tw/inst-sys/usr/lib64/libparted-fs-resize.so.0.0.2
lrwxrwxrwx   1 root     root           18 Mar  4 12:12 linux/suse/x86_64-tw/inst-sys/usr/lib64/libparted.so.2 -> libparted.so.2.0.2
-rwxr-xr-x   1 root     root       395056 Jan 15 16:35 linux/suse/x86_64-tw/inst-sys/usr/lib64/libparted.so.2.0.2
1422 blocks
```

- Note the `x86_64-tw` directory. `tw` comes directly from the `--dist` argument. `x86_64` is the architecture of the RPM.
- Everything below `inst-sys` is the part going to be used to update the installation system.
- The RPM in the `install` subdirectory is the package used by the installer for updating the target system.
- The `update.pre` and `update.post2` scripts are auto-generated to create resp. remove a temporary repository that contains this RPM.
- The `.update.XXX` file is added to the installation system and contains the RPM version. This way you easily see which
updates have been used to update the installation system.

### Using the driver update

Driver updates are used with the `dud` boot option as explained above.

There are two ways you can update the installation system: you can (a) pass an url pointing to
a driver update or (b) pass an url pointing to a plain RPM. In both cases slightly different things happen. Let's deal with
both cases individually.

To analyze issues with driver updates start the installation with the
`startshell=1` boot option. If you have network access (or simply prefer working that way) add `sshd=1 password=XXXXX` to
activate SSH access to your machine.

With `startshell=1`, the installation process is interrupted at the point
just before the installer would run. The installation system has been fully set up and any driver updates have been applied.
Once you exit the shell that has been started, the installation process continues.

#### Using a proper driver update

If everything went fine, looking around you should see:

```sh
0:vm0259:~ # ls -l /update/000/
total 4
-rw-r--r-- 1 root root 134 Mar  4 11:22 dud.config
drwxr-xr-x 3 root root  80 Mar  4 11:22 inst-sys
drwxr-xr-x 2 root root 100 Mar  4 11:22 install
drwxr-xr-x 2 root root  60 Mar  4 11:22 repo
```

This is the very content of `foo.dud`. Driver updates are stored in an
`/update` directory in the installation system. Each in its own subdirectory.

There is also an `/.update.XXX` file containing the package version used in the update:

```sh
0:vm0259:~ # ls -l /.update.*
lrwxrwxrwx 1 root root 65 Mar  4 11:22 /.update.c599d3ac-9bf7-48cb-b593-bd6612388049 -> /update/000/inst-sys/.update.c599d3ac-9bf7-48cb-b593-bd6612388049
0:vm0259:~ # cat /.update.c599d3ac-9bf7-48cb-b593-bd6612388049
libparted0-3.3-1.1.x86_64
```

If `/update` is missing, no driver update has been applied. Either because
none was downloaded or the product or architecture did not match.

You can check which product and architecture combination is expected
by looking at the `UpdateDir` entry in `/linuxrc.config`:

```sh
0:vm0259:~ # grep UpdateDir /linuxrc.config
UpdateDir:      /linux/suse/x86_64-tw
```

This must be the same directory you saw earlier in the cpio output of `foo.dud`.

Check `/proc/cmdline` that you passed the correct option:

```sh
0:vm0259:~ # cat /proc/cmdline 
initrd=initrd startshell=1 sshd=1 password=xxxxx dud=ftp://example.com/dud/foo.dud
```

If that's ok, check `/var/log/linuxrc.log` to see what happened. It should say the driver update
has been downloaded and log that it has been applied. Like this:

```sh
0:vm0259:~ # less /var/log/linuxrc.log
[...]
11:22:27 <4>: url = ftp://example.com/dud/foo.dud
11:22:27 <2>: loading ftp://example.com/dud/foo.dud -> /download/file_0000
11:22:27 <2>: sha1   655fb3c1df7aa7e27507e7db4b97ce96
11:22:27 <2>: sha256 8dc36c673e74b323f1f4707fc64ea4a7
11:22:27 <2>: digest not checked
[...]
11:22:30 <2>: dud 0: ftp:/linux/suse/x86_64-tw
11:22:30 <2>:  (id c599d3ac-9bf7-48cb-b593-bd6612388049)
11:22:30 <2>: 
11:22:30 <2>: dud 0:
11:22:30 <2>:   libparted0-3.3-1.1.x86_64       Wed Jan 15 15:33:15 2020
11:22:30 <1>: Driver Update: libparted0-3.3-1.1.x86_64  Wed Jan 15 15:33:15 2020
11:22:30 <1>: Driver Updates added:
11:22:30 <1>:   libparted0-3.3-1.1.x86_64       Wed Jan 15 15:33:15 2020
[...]
```

If that's all fine but things don't work as expected, check that the driver update has been properly integrated and
the updated files are actually used.

Files in the installation system are updated by replacing them with symlinks to the driver update. So if you expect
file `bar` to have been updated, it must be a symlink from `bar` to somewhere below `/update`. For example, let's
check if parted is using an updated libparted0:

```sh
0:vm0259:~ # type parted
parted is /usr/sbin/parted
0:vm0259:~ # ldd /usr/sbin/parted 
        linux-vdso.so.1 (0x00007ffe741ce000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f717f3a0000)
        libparted.so.2 => /usr/lib64/libparted.so.2 (0x00007f717f33a000)
[...]
0:vm0259:~ # ls -l /usr/lib64/libparted.so.2
lrwxrwxrwx 1 root root 18 Mar  4 11:22 /usr/lib64/libparted.so.2 -> libparted.so.2.0.2
0:vm0259:~ # ls -l /usr/lib64/libparted.so.2.0.2 
lrwxrwxrwx 1 root root 49 Mar  4 11:22 /usr/lib64/libparted.so.2.0.2 -> /update/000/inst-sys/usr/lib64/libparted.so.2.0.2
```

As you can see, `/usr/lib64/libparted.so.2.0.2` links to `/update/000/inst-sys/usr/lib64/libparted.so.2.0.2` which is
the file from our driver update.

This proves the driver update has been applied properly.

#### Using an RPM package

This works a bit differently compared to using a proper driver update. The idea here is to provide a convenient way
to update the installation system using just an RPM. The RPM is unpacked into some temporary directory and
files in the installation system are updated by replacing them with symlinks to this temporary directory.

There is no `/update` directory involved as described in the previous section.

But let's look at our example.

Check `/proc/cmdline` that you passed the correct option:

```sh
0:vm1479:~ # cat /proc/cmdline 
initrd=initrd startshell=1 sshd=1 password=xxxxx dud=ftp://example.com/dud/libparted0-3.3-1.1.x86_64.rpm

```

If that's ok, check `/var/log/linuxrc.log` to see what happened. It should say the RPM
has been downloaded and log that it has been unpacked. Like this:

```sh
0:vm1479:~ # less /var/log/linuxrc.log
[...]
11:15:40 <4>: url = ftp://example.com/dud/libparted0-3.3-1.1.x86_64.rpm
11:15:40 <2>: loading ftp://example.com/dud/libparted0-3.3-1.1.x86_64.rpm -> /download/file_0000
11:15:40 <2>: sha1   ee17a0800d6697e8a4acb5999d443c81
11:15:40 <2>: sha256 b1e8d4b229bcd219417212b96afcff59
11:15:40 <2>: digest not checked
[...]
11:15:44 <1>: ftp://example.com/dud/libparted0-3.3-1.1.x86_64.rpm: adding to installation system
11:15:44 <2>: ftp://example.com/dud/libparted0-3.3-1.1.x86_64.rpm -> /download/dud_0000: converting dud to squashfs
[...]
11:15:44 <1>: Driver Updates added:
11:15:44 <1>:   dud/libparted0-3.3-1.1.x86_64.rpm
[...]
```

If that's all fine but things don't work as expected, check that the RPM has been properly integrated and
the updated files are actually used.

Files in the installation system are updated by replacing them with symlinks to the temporary directory into
which the RPM has been unpacked.

```sh
0:vm1479:~ # type parted
parted is /usr/sbin/parted
0:vm1479:~ # ldd /usr/sbin/parted
        linux-vdso.so.1 (0x00007ffeab1e2000)
        libc.so.6 => /lib64/libc.so.6 (0x00007f5fb9d3e000)
        libparted.so.2 => /usr/lib64/libparted.so.2 (0x00007f5fb9cd8000)
[...]
0:vm1479:~ # ls -l /usr/lib64/libparted.so.2
lrwxrwxrwx 1 root root 18 Mar  4 11:15 /usr/lib64/libparted.so.2 -> libparted.so.2.0.2
0:vm1479:~ # ls -l /usr/lib64/libparted.so.2.0.2 
lrwxrwxrwx 1 root root 44 Mar  4 11:15 /usr/lib64/libparted.so.2.0.2 -> /mounts/mp_0006/usr/lib64/libparted.so.2.0.2
```

Notice that `libparted.so.2.0.2` is a symlink to somehwhere below `/mounts/mp_0006`.

But that's similar also for other files! For example:

```sh
0:vm1479:~ # ls -l /usr/lib64/libzypp.so.1722.0.0 
lrwxrwxrwx 1 root root 45 Mar  4 11:22 /usr/lib64/libzypp.so.1722.0.0 -> /mounts/mp_0001/usr/lib64/libzypp.so.1722.0.0
```

This is because the installation system consists of several parts put together by symlinking files.

You have to make sure that `/mounts/mp_0006` is not some regular part of the installation system but is really
your updated RPM.

One way to do this is:

```sh
0:vm1479:~ # findmnt --real
TARGET          SOURCE                                      FSTYPE   OPTIONS
/parts/mp_0000  /dev/loop0                                  squashfs ro,relatime
/parts/mp_0001  /dev/loop1                                  squashfs ro,relatime
/var/adm/mount  /dev/disk/by-id/scsi-3a849dd62eb66473d-part2
                                                            iso9660  ro,relatime,nojoliet,check=s,map=n,blocksize=2048
/mounts/mp_0000 /dev/loop2                                  squashfs ro,relatime
/mounts/mp_0001 /dev/loop3                                  squashfs ro,relatime
/mounts/mp_0002 /dev/loop4                                  squashfs ro,relatime
/mounts/mp_0003 /dev/loop5                                  squashfs ro,relatime
/mounts/mp_0004 /dev/loop6                                  squashfs ro,relatime
/mounts/mp_0006 /dev/loop7                                  squashfs ro,relatime
0:vm1479:~ # losetup -l
NAME       SIZELIMIT OFFSET AUTOCLEAR RO BACK-FILE                     DIO LOG-SEC
/dev/loop1         0      0         0  1 /parts/01_usr                   0     512
/dev/loop6         0      0         0  1 /download/file_0007 (deleted)   0     512
/dev/loop4         0      0         0  1 /download/file_0004 (deleted)   0     512
/dev/loop2         0      0         0  1 /download/file_0002 (deleted)   0     512
/dev/loop0         0      0         0  1 /parts/00_lib                   0     512
/dev/loop7         0      0         0  1 /download/dud_0000              0     512
/dev/loop5         0      0         0  1 /download/file_0006 (deleted)   0     512
/dev/loop3         0      0         0  1 /download/file_0003 (deleted)   0     512
```

You see that `/mounts/mp_0006` is from mounting `/dev/loop7` which is the loop device for `/download/dud_0000`.

If you want to know what the other parts of the installation system are, you can look at `/etc/instsys.parts`:

```sh
0:vm1479:~ # cat /etc/instsys.parts 
boot/x86_64/common /mounts/mp_0000
boot/x86_64/root /mounts/mp_0001
boot/x86_64/cracklib-dict-full.rpm /mounts/mp_0002
boot/x86_64/bind /mounts/mp_0003
boot/x86_64/yast2-trans-en_US.rpm /mounts/mp_0004
boot/x86_64/control.xml?copy=1 /mounts/mp_0005
```

It's pretty safe to assume that `/download/dud_0000` belongs to the updated RPM and is not a regular installation
system part. You can check `/var/log/linuxrc.log` as shown above to make sure, though.

Again, all the above proves the driver update has been applied properly.
