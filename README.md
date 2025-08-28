# mkdud

## About

This is about driver updates for openSUSE/SLES. If you're not familiar with them, please look at
- http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/index.html
- http://en.opensuse.org/SDB:Linuxrc#p_driverupdate

`mkdud` is a tool that makes it easy to create driver updates for SUSE distributions.

## Downloads

Packages for openSUSE and SLES are built at the [openSUSE Build Service](https://build.opensuse.org). You can grab

- [official releases](https://software.opensuse.org/package/mkdud) or

- [latest stable versions](https://software.opensuse.org/download/package?project=home:snwint:ports&package=mkdud)
  from my [ports](https://build.opensuse.org/package/show/home:snwint:ports/mkdud) project

## Blog

See also my mini-series of articles around SUSE installation media and driver updates that highlight specific use-cases:

- [Update the update process!](https://lizards.opensuse.org/2017/02/16/fun-things-to-do-with-driver-updates)
- [But what if I need a new kernel?](https://lizards.opensuse.org/2017/03/16/fun-things-to-do-with-driver-updates-2)
- [And what if I want to **remove** some files?](https://lizards.opensuse.org/2017/04/25/fun-things-to-do-with-driver-updates-3)
- [Encrypted installation media](https://lizards.opensuse.org/2017/11/17/encrypted-installation-media)

## Usage

### Overview

Driver updates (DUDs) are used to apply fixes to the installation process. In particular you can:

- update kernel modules
- change files in the initrd of the installation medium
- change files in the installation system / live root of the installation medium
- change boot options
- change installer config options
- provide updated packages to be installed
- add scripts to be run before and after the installer runs

The format of DUDs is described in the [Update Media Howto](http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/Update-Media-HOWTO.html).

`mkdud` provides an easy way to create these DUDs.

See [HOWTO](HOWTO.md) for detailed instructions.

### DUD formats

The DUD will be packaged into an archive and optionally compressed. The
default is a gzipped cpio archive. You can also create an RPM or ISO image.

If you create an RPM (use --format=rpm) you can sign the RPM in the usual RPM-way
to get a signed DUD.

There is an advantage in using cpio instead of tar or rpm: because the Linux kernel
understands cpio archives, you can just append a DUD to the initrd on the
boot medium to apply it (literally: 'cat my.dud >> initrd'). No need for a
'dud' boot option in this case.

### DUD directory structure

Please read section 2.1 [Directory structure] in the
[Update Media Howto](http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/Update-Media-HOWTO.html) first.

The DUD directory layout allows for an optional top-level directory consisting of a decimal number.
The intention is to avoid file collisions between different DUDs.

For example, imagine you want to include your driver update directly into
the `initrd`. You can do this simply by appending a DUD
to the `initrd`. But when someone else tries this again, they will get into
trouble as the directories are just merged. To avoid this, choose a
directory prefix that's unlikely to conflict with others using the
`--prefix` option.

### Signature

When downloading a driver update the installer will verify the integrity of
the update by checking the (detached) signature.

## openSUSE Development

To build, simply run `make`. Install with `make install`.

Basically every new commit into the master branch of the repository will be auto-submitted
to all current SUSE products. No further action is needed except accepting the pull request.

Submissions are managed by a SUSE internal [jenkins](https://jenkins.io) node in the InstallTools tab.

Each time a new commit is integrated into the master branch of the repository,
a new submit request is created to the openSUSE Build Service. The devel project
is [system:install:head](https://build.opensuse.org/package/show/system:install:head/mkdud).

`*.changes` and version numbers are auto-generated from git commits, you don't have to worry about this.

The spec file is maintained in the Build Service only. If you need to change it for the `master` branch,
submit to the
[devel project](https://build.opensuse.org/package/show/system:install:head/mkdud)
in the build service directly.

Development happens exclusively in the `master` branch. The branch is used for all current products.

You can find more information about the changes auto-generation and the
tools used for jenkis submissions in the [linuxrc-devtools
documentation](https://github.com/openSUSE/linuxrc-devtools#opensuse-development).

## License

The project is using [GPL-3.0](https://opensource.org/licenses/GPL-3.0).
