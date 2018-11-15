# Driver updates and you

Driver updates provide a way to update kernel drivers and to influence the
installation workflow **during the installation** of SUSE Linux.
Kernel modules on the running system are updated with the usual update process (of the kernel rpm).

They are described in the [Update Media Howto](http://ftp.suse.com/pub/people/hvogel/Update-Media-HOWTO/Update-Media-HOWTO.html)

A driver update can be either an archive file or a directory (the unpacked archive).


## Use driver updates

1. Use the `dud` boot option to pass a URL pointing to the driver update. For example:

    - `dud=https://example.com/foo.dud`
    - `dud=disk:/foo.dud`

2. Driver updates in special places are loaded automatically:

    - a file named `driverupdate` in the root directory of the installation medium
    - a partition (e.g. on a USB stick) with file system label `OEMDRV` containing an unpacked driver update
    - an unpacked driver update in the initrd of the installation medium

Putting the driver update into the initrd provides a way to seamlessly integrate driver updates into otherwise
unchanged SUSE installation media. The `mksusecd` command has a dedicated `--initrd` option to make this easy:

```sh
mksusecd --create new.iso --initrd foo.dud old.iso
```


## Create driver updates

To create driver updates use `mkdud`. You have to specify at least the product the driver update in intended for but it's
also nice to give it a descriptive name:

```sh
mkdud --create foo.dud --dist leap15.0 --name "Support the new bar" bar.ko
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


## Adjust installation workflow

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


## Execute commands

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


## Debug problems

Sometimes things just don't work as expected. Here's what to do:

- use `mkdud --show foo.dud` to get an overview of what's inside the driver update
- make sure the product specified with `--dist` matches the intended product

If you see the driver update loaded but it's apparently not applied, do this:

- start the installation with the `startshell=1` boot option; this will open a shell instead of starting the installer (the regular
workflow continues when you exit this shell)
- there must be an `/update` directory with subdirectories for each driver update; if it's missing, your driver update has not been recognized
- check the correct product: the `UpdateDir` entry in `/linuxrc.config` contains the expected string
- have a look at `/var/log/linuxrc.log` to see what linuxrc did with the driver update so far
