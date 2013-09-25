#!/usr/bin/env bash

AUR_BUILD_ORDER=(
  aur/libindicator
  aur/system-tools-backends
  aur/liboobs
  aur/libxnvctrl
)

MATE_BUILD_ORDER=(
  mate-common
  mate-doc-utils
  mate-desktop
  libmatekeyring
  mate-keyring
  libmatekbd
  libmatewnck
  libmateweather
  mate-icon-theme
  mate-dialogs
  mate-file-manager
  mate-polkit
  mate-window-manager
  mate-settings-daemon
  mate-menus
  mate-panel
  mate-session-manager
  mate-backgrounds
  mate-themes
  mate-notification-daemon
  mate-image-viewer
  mate-control-center
  mate-screensaver
  mate-file-archiver
  mate-media
  mate-power-manager
  mate-system-monitor
  caja-dropbox
  mate-applets
  mate-calc
  mate-character-map
  mate-document-viewer
  mate-file-manager-gksu
  mate-file-manager-image-converter
  mate-file-manager-open-terminal
  mate-file-manager-sendto
  mate-bluetooth
  mate-file-manager-share
  mate-icon-theme-faenza
  mate-indicator-applet
  mate-menu-editor
  mate-netbook
  mate-netspeed
  mate-sensors-applet
  mate-system-tools
  mate-terminal
  mate-text-editor
  mate-user-share
  mate-utils
  python-caja
)

BASEDIR=$(dirname $(readlink -f ${0}))

# Show usgae information
function usage() {
    echo "$(basename ${0}) - MATE build tool for Arch Linux"
    echo
    echo "Usage: $(basename ${0}) -t [task]"
    echo
    echo "Options:"
    echo "-h  Shows this help message."
    echo "-t  Provide a task to run which can be one of:"
    echo "  audit       Show which packages remain to be built."
    echo "  build       Build MATE packages."
    echo "  check       Check upstream for new source tarballs."
    echo "  clean       Clean sources using 'make maintainer-clean' and remove 'src' directories."
    echo "  delete      Delete Arch Linux 'pkg.tar.xz binary package files."
    echo "  purge       Purge source tarballs and 'src' directories "
    echo "  uninstall   Uninstall MATE packages and dependencies."
    echo
    echo "Each of the tasks above run automatically and operate over the entire package tree."
    exit 1
}

# Show packages that are not yet built.
function tree_audit() {
    local PKG=${1}
    cd ${PKG}
    if [[ "${PKG}" == *python* ]]; then
        PKG=$(echo ${PKG} | sed 's/python/python2/')
    fi
    local PKGBUILD_VER=$(grep -E ^pkgver PKGBUILD | cut -f2 -d'=')
    local PKGBUILD_REL=$(grep -E ^pkgrel PKGBUILD | cut -f2 -d'=')
    local PKGBUILD=${PKGBUILD_VER}-${PKGBUILD_REL}
    local EXISTS=$(ls -1 *${PKGBUILD}*.pkg.tar.xz 2>/dev/null)
    if [ -z "${EXISTS}" ]; then
        echo " - ${PKG} needs building"
    elif [ -d pkg ]; then
        local STATIC=$(find pkg/ -name *.a)
        if [ -n "${STATIC}" ]; then
            echo " - ${PKG} contains static files, delete them in PKGBUILD."
            echo " +---> ${STATIC}"
        fi
    fi
}

# Build packages that are not at the current version
function tree_build() {
    local PKG=${1}
    cd ${PKG}
    if [[ "${PKG}" == *python* ]]; then
        PKG=$(echo ${PKG} | sed 's/python/python2/')
    fi
    local INSTALLED=$(pacman -Q `basename ${PKG}` 2>/dev/null | cut -f2 -d' ')
    local PKGBUILD_VER=$(grep -E ^pkgver PKGBUILD | cut -f2 -d'=')
    local PKGBUILD_REL=$(grep -E ^pkgrel PKGBUILD | cut -f2 -d'=')
    local PKGBUILD=${PKGBUILD_VER}-${PKGBUILD_REL}
    local EXISTS=$(ls -1 *${PKGBUILD}*.pkg.tar.xz 2>/dev/null)
    if [ -z "${EXISTS}" ]; then
        echo " - Building ${PKG}"
        makepkg -fs --noconfirm --needed --log
        if [ $? -ne 0 ]; then
            echo " - Failed to build ${PKG}. Stopping here."
            exit 1
        else
            sudo makepkg -i --noconfirm --asroot
            echo
            echo
            sleep 5
        fi
    else
        echo " - ${PKG} is built and current."
    fi
}

# Check for new upstream releases
function tree_check() {
    local PKG=${1}
    if [ ! -f /tmp/SHA1SUMS ]; then
        echo " - Downloading SHA1SUMS"
        wget -c -q http://pub.mate-desktop.org/releases/1.6/SHA1SUMS -O /tmp/SHA1SUMS
    fi
    echo " - Checking ${PKG}"
    IS_UPSTREAM=$(grep -E ${PKG}-[0-9]. /tmp/SHA1SUMS)
    if [ -n "${IS_UPSTREAM}" ]; then
        local UPSTREAM_TARBALL=$(grep -E ${PKG}-[0-9]. /tmp/SHA1SUMS | cut -c43- | tail -n1)
        local DOWNSTREAM_VER=$(grep -E ^pkgver ${PKG}/PKGBUILD | cut -f2 -d'=')
        local DOWNSTREAM_TARBALL="${PKG}-${DOWNSTREAM_VER}.tar.xz"
        local UPSTREAM_SHA1=$(grep -E ${PKG}-[0-9]. /tmp/SHA1SUMS | cut -c1-40 | tail -n1)
        local DOWNSTREAM_SHA1=$(grep -E ^sha1 ${PKG}/PKGBUILD | cut -f2 -d"'")
        if [ "${UPSTREAM_TARBALL}" != "${DOWNSTREAM_TARBALL}" ]; then
            echo " +---> Upstream tarball differs : ${UPSTREAM_TARBALL}"
        fi
        if [ "${UPSTREAM_SHA1}" != "${DOWNSTREAM_SHA1}" ]; then
            echo " +---> Upstream SHA1SUM differs : ${UPSTREAM_SHA1}"
        fi
    else
        echo " +---> No upstream version of ${PKG} detected. Skipping."
    fi
}

# Clean the sources using `make maintainer-clean`
function tree_clean() {
    local PKG=${1}
    for SRC in ${PKG}/src/*
    do
        if [ -f ${SRC}/Makefile ]; then
            echo " - Cleaning ${SRC}"
            make maintainer-clean 2>&1 /dev/null
        fi
    done
}

# Delete all binary package files.
function tree_delete() {
    local PKG=${1}
    for PACKAGE in ${PKG}/*.pkg.tar.xz
    do
        echo " - Deleting ${PACKAGE}"
        rm -f ${PACKAGE}
    done
}

# Remove source tarballs
function tree_purge() {
    local PKG=${1}
    # Remove all source tarballs, don't bother checking versions just ditch them all.
    for TARBALL in ${PKG}/*.tar.{b,g,x}z*
    do
        if [ -f ${TARBALL} ] && [[ "${TARBALL}" != *pkg* ]]; then
            echo " - Deleting ${TARBALL}"
            rm -f ${TARBALL}
        fi
    done

    # Remove the any 'src' directories created by `makepkg`.
    if [ -d ${PKG}/src ]; then
        echo " - Deleting ${PKG}/src"
        rm -rf $${PKG}/src
    fi
}

# Uninstall MATE packages and orphans from the system.
function tree_uninstall() {
    echo "Action : uninstall"
    local INSTALLED_PKGS=$(pacman -Qq)
    local UNINSTALL_PKGS=""
    local BUILD_ORDER=( ${AUR_BUILD_ORDER[@]} ${MATE_BUILD_ORDER[@]} )
    cd ${BASEDIR}
    for PKG in ${BUILD_ORDER[@]};
    do
        PKG=$(basename ${PKG})
        if [[ "${PKG}" == *python* ]]; then
            PKG=$(echo ${PKG} | sed 's/python/python2/')
        fi
        if [ -n "$(echo ${INSTALLED_PKGS} | grep ${PKG})" ]; then
            UNINSTALL_PKGS="${UNINSTALL_PKGS} ${PKG}"
        fi
    done
    sudo pacman -Rs --noconfirm ${UNINSTALL_PKGS}
}

function tree_run() {
    local ACTION=${1}
    echo "Action : ${ACTION}"
    local BUILD_ORDER=( ${AUR_BUILD_ORDER[@]} ${MATE_BUILD_ORDER[@]} )
    for PKG in ${BUILD_ORDER[@]};
    do
        cd ${BASEDIR}
        tree_${ACTION} ${PKG}
    done
}

TASK=""
OPTSTRING=ht:
while getopts ${OPTSTRING} OPT; do
    case ${OPT} in
        h) usage;;
        t) TASK=${OPTARG};;
        *) usage
    esac
done
shift "$(( $OPTIND - 1 ))"

if [ "${TASK}" == "audit" ] ||
   [ "${TASK}" == "build" ] ||
   [ "${TASK}" == "check" ] ||
   [ "${TASK}" == "clean" ] ||
   [ "${TASK}" == "delete" ] ||
   [ "${TASK}" == "purge" ]; then
    tree_run ${TASK}
elif [ "${TASK}" == "uninstall" ]; then
    tree_uninstall
else
    echo "ERROR! You've asked me to do something I don't understand."
    echo
    usage
fi

# Clean up
if [ -f /tmp/SHA1SUMS ]; then
    rm -f /tmp/SHA1SUMS
fi
