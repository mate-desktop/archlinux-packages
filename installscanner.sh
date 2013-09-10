#!/usr/bin/env bash

echo "WARNING! This utility script is not documented yet."
echo "Do not run this unless you fully understand what it does."
echo "flexiondotorg will integrate this with makerpo at some point."
exit 0

function make_install_script() {
    echo "post_install() {" > ${INSTALL_FILE}
    if [ ${SCHEMAS} -eq 1 ]; then
        echo "    glib-compile-schemas /usr/share/glib-2.0/schemas/" >> ${INSTALL_FILE}
    fi
    if [ ${MIME} -eq 1 ]; then
        echo "    update-mime-database /usr/share/mime/ > /dev/null" >> ${INSTALL_FILE}
    fi
    if [ ${ICONS} -eq 1 ]; then
        for ICON_DIR in ${ICON_ARRAY[@]}; do
            echo "    gtk-update-icon-cache -q -t -f /usr/share/icons/${ICON_DIR}" >> ${INSTALL_FILE}
        done
    fi
    if [ ${APP_DESKTOP} -eq 1 ]; then
        echo "    update-desktop-database -q" >> ${INSTALL_FILE}
    fi
    echo "}" >> ${INSTALL_FILE}
    echo >> ${INSTALL_FILE}
    echo "pre_upgrade() {" >> ${INSTALL_FILE}
    echo "    pre_remove" >> ${INSTALL_FILE}
    echo "}" >> ${INSTALL_FILE}
    echo >> ${INSTALL_FILE}
    echo "post_upgrade() {" >> ${INSTALL_FILE}
    echo "    post_install" >> ${INSTALL_FILE}
    echo "}" >> ${INSTALL_FILE}
    echo >> ${INSTALL_FILE}
    echo "pre_remove() {" >> ${INSTALL_FILE}
    if [ ${SCHEMAS} -eq 1 ]; then
        echo "    glib-compile-schemas /usr/share/glib-2.0/schemas/" >> ${INSTALL_FILE}
    else
        echo "    :" >> ${INSTALL_FILE}
    fi
    echo "}" >> ${INSTALL_FILE}
    echo >> ${INSTALL_FILE}
    echo "post_remove() {" >> ${INSTALL_FILE}
    PASS=$((${MIME} + ${ICONS} + ${APP_DESKTOP}))
    if [ ${PASS} -eq 0 ]; then
        echo "    :" >> ${INSTALL_FILE}
    else
        if [ ${MIME} -eq 1 ]; then
            echo "    update-mime-database /usr/share/mime/ > /dev/null" >> ${INSTALL_FILE}
        fi
        if [ ${ICONS} -eq 1 ]; then
            for ICON_DIR in ${ICON_ARRAY[@]}; do
                echo "    gtk-update-icon-cache -q -t -f /usr/share/icons/${ICON_DIR}" >> ${INSTALL_FILE}
            done
        fi
        if [ ${APP_DESKTOP} -eq 1 ]; then
            echo "    update-desktop-database -q" >> ${INSTALL_FILE}
        fi
    fi
    echo "}" >> ${INSTALL_FILE}
}

rm -f gtk-update-icon-cache.txt
rm -f desktop-utils.txt
rm -f shared-mime-info.txt
rm -f delete-install.txt

for DIR in *; do
    if [ -d ${DIR} ] && [ "${DIR}" != "aur" ]; then
        SCHEMAS=0
        MIME=0
        ICONS=0
        APP_DESKTOP=0
        if [ -d ${DIR}/pkg ]; then
            echo "${DIR} has a package. Checking..."
            if [ -d ${DIR}/pkg/*/usr/share/glib-2.0/schemas ]; then
                echo " - glib schemas detected"
                SCHEMAS=1
            fi
            if [ -d ${DIR}/pkg/*/usr/share/mime ]; then
                echo " - mime types detected, 'shared-mime-info' required in the PKGBUILD 'depends'."
                echo `basename ${DIR}` >> shared-mime-info.txt
                MIME=1
            fi
            if [ -d ${DIR}/pkg/*/usr/share/icons ]; then
                echo " - icons detected, 'gtk-update-icon-cache' required in the PKGBUILD depends"
                echo `basename ${DIR}` >> gtk-update-icon-cache.txt
                ICONS=1
                declare -a ICON_ARRAY=()
                for ICON in ${DIR}/pkg/*/usr/share/icons/*; do
                    if [ -d ${ICON} ]; then
                        ICON_NAME=`basename ${ICON}`
                        ICON_ARRAY=("${ICON_ARRAY[@]}" "${ICON_NAME}")
                    fi
                done
                echo " + ${ICON_ARRAY[@]}"
            fi
            if [ -d ${DIR}/pkg/*/usr/share/applications ]; then
                echo " - desktop files detected, 'desktop-utils-required in the PKGBUILD 'depends'"
                echo `basename ${DIR}` >> desktop-utils.txt
                APP_DESKTOP=1
            fi
            INSTALL_REQUIRED=$((${SCHEMAS} + ${MIME} + ${ICONS} + ${APP_DESKTOP}))
            INSTALL_NAME="`basename ${DIR}`.install"
            INSTALL_FILE="${DIR}/${INSTALL_NAME}"
            if [ ${INSTALL_REQUIRED} -ge 1 ]; then
                echo " - ${INSTALL_FILE} file is required."
                make_install_script
            else
                echo " - ${INSTALL_NAME} file not required."
                if [ -f ${DIR}/*.install ]; then
                    echo " - Found one for deleting."
                    rm -f ${DIR}/*.install
                    echo `basename ${DIR}` >> delete-install.txt
                fi
            fi
        else
            echo "${DIR} doesn't have a package. Skipping."
        fi
    fi
    echo
done
