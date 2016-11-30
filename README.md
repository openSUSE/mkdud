# mkdud

This is about driver updates. If you're not familiar with them, please look at
http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/index.html and
http://en.opensuse.org/SDB:Linuxrc#p_driverupdate first.

## Usage

### Updating RPMs

If you need to update packages during installation via driver update, either
in the installation environment or the final installed system, this script
helps you to setup such a driver update.

There are two ways for this:

* (a) The old ('rpm') way: place all rpms into the `install` directory and YaST
  will run `rpm -U install/*.rpm` at the end of the first installation stage.

* (b) Since SLE11/openSUSE 12.1 YaST lets you register a repository automatically.
  The repo priority can be set higher (numerically lower) than the default
  priority (99) to ensure the driver update packages are preferred.

Method (b) has the advantage that the old packages are never installed and
used and conflicts and dependencies are automatically resolved (think of
different kernel flavors).

This script supports both ways.

Examples:

* (1) update perl-Bootloader with method (a) _and_ (b), repo priority is 50:

<pre>
  # mkdud --dist sle11 --create foo1.dud perl-Bootloader.rpm
</pre>

* (2) update perl-Bootloader and yast2-bootloader for both i586 and x86_64, using
  only method (b), repo priority is 90:

<pre>
  # ls perl-Bootloader/binaries/* yast2-bootloader/binaries/*
  perl-Bootloader/binaries/perl-Bootloader-0.4.89.30-1.10.i586.rpm
  yast2-bootloader/binaries/yast2-bootloader-2.17.78-1.1.i586.rpm
  perl-Bootloader/binaries/perl-Bootloader-0.4.89.30-1.10.x86_64.rpm
  yast2-bootloader/binaries/yast2-bootloader-2.17.78-1.1.x86_64.rpm
</pre>

<pre>
  # mkdud --install repo --prio 90 --dist sle11 --create foo2.dud perl-Bootloader/binaries/* yast2-bootloader/binaries/*
</pre>


* (3) replace yast2-bootloader only in the installation system, for i586 and x86_64:

<pre>
  # ls yast2-bootloader/binaries/*
  yast2-bootloader/binaries/yast2-bootloader-2.17.78-1.1.i586.rpm
  yast2-bootloader/binaries/yast2-bootloader-2.17.78-1.1.x86_64.rpm
</pre>

<pre>
  # mkdud --install instsys --dist sle11 --create foo3.dud yast2-bootloader/binaries/*
</pre>

There's still a catch: if you build the RPM yourself or in the openSUSE
Build Service and so the RPM is probably signed with a key that is not included on the
install media, you'll get a warning that the package could not be verified
during installation.

For this, `mkdud` can handle public gpg keys. You just add them on the command
line. For example:

<pre>
  # mkdud -c foo.dud -d sle12 bar.rpm bar.pub
</pre>

will integrate bar.pub into the RPM key database so it is used to verify
bar.rpm.

Note that these keys are not copied into the target system. They are only
part of the installation environment.

### Adding and running programs

Sometimes you need to include and run a script to fix things. For example

<pre>
  # mkdud --dist sle11 --exec bar --create foo4.dud bar
</pre>

adds 'bar' to the 'install' directory and runs it. Unlike the 'update.pre'
script it is run just after the dud has been read, even _before_ any dud
modules are loaded.

You can combine this with rpms:

<pre>
  # mkdud --install instsys --dist sle11 --exec fix_it --create foo5.dud yast2-bootloader/binaries/* fix_it
</pre>

This replaces yast2-bootloader and also adds and runs the `fix_it` script.

### Conditional DUDs

If a DUD must only be applied to certain machines or only to specific
service packs, you can add a condition script that is run when the DUD
config file is parsed during installation. This script must exit with 0 to
indicate that it's ok to continue with the DUD. If the exit code is nonzero
a message is printed that the update will not be applied and the update is
deleted.

`mkdud` can generate scripts automatically that check for sle10 and sle11
service packs. They are used if you name the script `ServicePackN`. If you
want to use your own scripts with such a name, specify it e.g. as
`./ServicePack1` on the command line.

### DUD formats

The DUD will be packaged into an archive and optionally compressed. The
default is a gzipped cpio archive. For SLE12 and later you can also
create an rpm.

Situation prior to SLE12, openSUSE 13.2:

> Due to a limitation in linuxrc you can't use a compressed DUD when you
> need to sign it. (The verification in linuxrc will fail.) So, if you need
> to create a signed DUD, don't compress it (use --format=cpio).

SLE12, openSUSE 13.2, and later versions:

>  You can use either a cpio or tar archive and can compress it optionally
>  with either gzip or xz. All formats may be used for signed DUDs.

SLE12-SP1, Leap-42.1 and later versions:

> If you create an RPM (use --format=rpm) you can sign the RPM in the usual RPM-way
> to get a signed DUD.

There is an advantage in using cpio instead of tar or rpm: because the Linux kernel
understands cpio archives, you can just append a DUD to the initrd on the
boot medium to apply it (literally: 'cat my.dud >> initrd'). No need for a
'dud' boot option in this case.

It is also possible to create a DUD in ISO9660 format. But note that DUDs in
*compressed* (gzip or xz) ISO9660 format are currently not suitable to be
used in the installer's 'dud' boot option.

### DUD directory structure

Please read section 2.1 [Directory structure] in the Update-Media-HOWTO above first.

Normally, `mkdud` ensures a correct directory layout. But sometimes you may
want to specify a directory prefix yourself.

For example, imagine you want to include your driver update directly into
the `initrd`. You can do this simply by appending an (unsigned) driver update
to the `initrd`. But when someone else tries this again, they will get into
trouble as the directories are just merged. To avoid this, choose a
directory prefix that's unlikely to conflict with others using the
`--prefix` option.

If this sounds a bit complicated just try the `--prefix` option and look at
the unpacked driver update.

### Signature

When downloading a driver update the installer will verify the integrity of
the update by checking the (detached) signature.

Note that for sle11 due to a limitation in the installer you can only sign
an uncompressed update. sle12/openSUSE 13.2 and later don't have this
limitation.

## openSUSE Development

The package is automatically submitted from the `master` branch to
[system:install:head](https://build.opensuse.org/package/show/system:install:head/mkdud)
OBS project. From that place it is forwarded to
[openSUSE Factory](https://build.opensuse.org/project/show/openSUSE:Factory).

You can find more information about this workflow in the [linuxrc-devtools
documentation](https://github.com/openSUSE/linuxrc-devtools#opensuse-development).
