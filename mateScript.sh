#!/bin/bash -e
set -e

 #working sometimes :D  I have to code something to handle missing dependencies

listofpackages=(
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
    mate-session-manager
    mate-menus
    mate-panel
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
    #caja-dropbox # fail
    mate-applets
    mate-bluetooth
    mate-calc
    mate-character-map
    mate-document-viewer
    #mate-file-manager-gksu # automake-1.13 fail
    mate-file-manager-image-converter
    mate-file-manager-open-terminal
    mate-file-manager-sendto
    #mate-file-manager-share # automake-1.13 fail
    mate-icon-theme-faenza
    #mate-indicator-applet # not in archlinux-packages yet
    mate-menu-editor
    #mate-netbook # not in archlinux-packages yet
    mate-netspeed
    mate-sensors-applet
    #mate-system-tools # automake-1.13 fail
    mate-terminal
    mate-text-editor
    #mate-user-share # automake-1.13 fail
    mate-utils
    #python-caja # not in archlinux-packages yet
    libindicator # not a MATE 1.6 package
    #mate-display-manager # not a MATE 1.6 package # fail
    )


for package in ${listofpackages[@]}
	do
	echo " "
	echo "----->  Starting $package build"
	cd $package

	if [ -f *.pkg.tar.xz ];
	then echo "----- $package package already built ^^ I'm checking if it's already installed..."
			if [[  `pacman -Qqe | grep "$package"` ]];
				then installed_pkg_stuff=$(pacman -Q | grep $package);
		#those operations could be done/written in a shorter [but a little more complex] way. I choose to let it this way to have a "readable" code
		newver=$(cat PKGBUILD | grep pkgver=) && newver=${newver##pkgver=};
		installedver=$(pacman -Q | grep $package) && installedver=${installedver##$package} && installedver=${installedver%%-*};

				if [ $newver == $installedver ]
						then  echo "!****! The same version of package $package is already  installed,skipping...."
				fi
			fi
	else (echo "---------- START Making ->  $package -------------------" && makepkg --asroot ) && sudo pacman -U --noconfirm $package-*.pkg.tar.xz
	fi

#break if there is some error
  if [ $? -ne 0 ]
  then
    break
  fi


echo "-----> Done building & installing $package"
echo " "

cd ..
done
