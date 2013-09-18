# Introduction

These are the [PKGBUILD files](https://wiki.archlinux.org/index.php/PKGBUILD)
that produce [MATE desktop](http://www.mate-desktop.org) packages for
[Arch Linux](http://www.archlinux.org).

Binary packages are built from these PKGBUILD files periodically sent via `rsync`
to the official MATE repository for Arch Linux.

  * <http://packages.mate-desktop.org/repo/archlinux/mate/>

## Installing MATE on Arch Linux

The following references will assit you:

  * <http://wiki.mate-desktop.org/archlinux_custom_repo>
  * <https://wiki.archlinux.org/index.php/MATE>

# Developing MATE packages for Arch Linux

Any help you can offer is most welcomed. The following will hopefully help.

## Submitting bugs

Please submit Arch Linux packaging bugs for MATE desktop to the
[archlinux-packages](https://github.com/mate-desktop/archlinux-packages)
GitHub [issue tracker](https://github.com/mate-desktop/archlinux-packages/issues?state=open).

## Fixing bugs

If you fix a bug in one of the MATE desktop PKGBUILDs, please submit a pull-request
to the [archlinux-packages](https://github.com/mate-desktop/archlinux-packages)
GitHub repository. Please **do not ** submit a new PKGBUILD to the [AUR](https://aur.archlinux.org/),
this just creates confusion.

## Common issues

Here are some common issues you may run into when packaging MATE desktop components
for Arch Linux.

### PKGBUILD depends

Some common `depends` for a MATE related package are:

   * To
   * be
   * written

### PKGBUILD makedepends

`mate-common` is a build requirement, it is likely required in any MATE related
package. It **should not** need to be installed on an end-users system.

### Python

As the time of writting any Python programs/libraries in MATE 1.6 require
Python 2. However, Python 2 is the default on Arch Linux therefore PKGBUILDs
need to force the use of `python2` in the following ways:

  * Set the `PYTHON` environment variable to `/usr/bin/python2`
  * Remove any Python byte-code from the packages.
  * Change the Python interpreter in shebang of any Python "executables".

Examples of all of the above can be found in the [mate-applets](https://github.com/mate-desktop/archlinux-packages/blob/master/mate-applets/PKGBUILD)
PKGBUILD file.

### libexec

Arch Linux does not have a `/usr/libexec` directory. Therefore if any packages
install files to `/usr/libexec` the PKGBUILD needs to set `--libexecdir=/usr/lib/${pkgname}`
via `configure` or `autogen.sh` otherwise the application in question will not work.

An examples of this can be found in the [mate-power-manager](https://github.com/mate-desktop/archlinux-packages/blob/master/mate-power-manager/PKGBUILD)
PKGBUILD file.

### sbin

Arch Linux recently moved all binaries to `/usr/bin`. Therefore if any packages
install files to `/usr/sbin` the PKGBUILD needs to set `--sbindir=/usr/bin` via
`configure` or `autogen.sh` to avoid conflicting with the `filesystem` package.

An examples of this can be found in the [mate-control-center](https://github.com/mate-desktop/archlinux-packages/blob/master/mate-control-center/PKGBUILD)
PKGBUILD file.

# Building MATE packages

If you want to help the MATE packaging team for Arch Linux then you'll like
want to build MATE packages yourself to test your changes before submitting
a pull-request.

## Use a `chroot`

It is highly recommends you use a `chroot` to create a sandbox for build the MATE
packages. [archroot-builder](https://github.com/flexiondotorg/archroot-builder) can
assist with that.

## `makerpo`

`makerpo` is a shell script that can build the entire MATE package tree for Arch
Linux. You'll find it in the same directory as this README. `makerpo -h` will help
get you started, but the magic incantation is:

    ./makerpo -t build -a

The above will automatically build every package, or just the one's that have new
version that is unbuilt.

### build.log

If you have difficulty getting a package to build, then `makerpo` will keep a
`build.log` file for each package. This can be useful to identify missing
requirements or to share with the MATE developers so they can assist. They like
the logs pasting here:

  * <http://paste.mate-desktop.org/>
