#!/bin/sh -e
#
# ==============================================================================
# PAQUETE: canaima-semilla
# ARCHIVO: scripts/functions/image.sh
# DESCRIPCIÓN: Funciones para la modificación del árbol de configuración.
# COPYRIGHT:
#       (C) 2010-2012 Luis Alejandro Martínez Faneyth <luis@huntingbears.com.ve>
#       (C) 2012 Niv Sardi <xaiki@debian.org>
# LICENCIA: GPL-3
# ==============================================================================
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# COPYING file for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.
#
# CODE IS POETRY

CS_CLEAN_TREE() {

	# ======================================================================
	# FUNCIÓN: CS_CLEAN_TREE
	# DESCRIPCIÓN: Limpia el árbol de configuración.
	# ENTRADAS:
	#       [ISOS]: Directorio donde se encuentra el árbol de configuración.
	#       [CS_OP_MODE]: Modo de operación. 
	#       [CS_PRINT_MODE]: Modo de verbosidad.
	# ======================================================================

	ISOS="${1}"
	[ -n "${ISOS}" ] && shift 1 || true
	CS_OP_MODE="${1}"
	[ -n "${CS_OP_MODE}" ] && shift 1 || true
	CS_PRINT_MODE="${1}"
	[ -n "${CS_PRINT_MODE}" ] && shift 1 || true

	THISTORYCONF="${ISOS}/history/config"
	THISTORYLOG="${ISOS}/history/log"
	TCONF="${ISOS}/config"
	TCONFBKP="${THISTORYCONF}/${DATE}"

	if [ "${CS_OP_MODE}" != "vardump" ]; then
		if [ -d "${TCONF}" ]; then
			INFOMSG "Respaldando árbol de configuraciones previo en '%s'." "${TCONFBKP}"
			${BIN_MKDIR} -p "${THISTORYCONF}"
			${BIN_MKDIR} -p "${THISTORYLOG}"
			${BIN_MV} "${TCONF}" "${TCONFBKP}"
			for LOGFILEBKP in ${ISOS}/*.log; do
				if [ "${LOGFILEBKP}" != "${ISOS}/${LOGFILE}" ]; then
					${BIN_MV} ${LOGFILEBKP} "${THISTORYLOG}/"
				fi
			done
		fi

		WARNINGMSG "Limpiando residuos de construcciones anteriores ..."
		cd "${ISOS}" && ${BIN_LB} clean --all 1>/dev/null 2>&1
	fi
}

CS_CREATE_TREE() {

	# ======================================================================
	# FUNCIÓN: CS_CREATE_TREE
	# DESCRIPCIÓN: Crea el árbol de configuración a partir de los valores
	#	      del perfil procesados por CS_LOAD_PROFILE.
	# ENTRADAS:
	#       [ISOS]: Directorio donde se encuentra el árbol de configuración.
	#       [CS_OP_MODE]: Modo de operación. 
	#       [CS_PRINT_MODE]: Modo de verbosidad.
	# ======================================================================

	ISOS="${1}"
	[ -n "${ISOS}" ] && shift 1 || true
	CS_OP_MODE="${1}"
	[ -n "${CS_OP_MODE}" ] && shift 1 || true
	CS_PRINT_MODE="${1}"
	[ -n "${CS_PRINT_MODE}" ] && shift 1 || true

	TCSCONFFILE="${ISOS}/config/c-s/tree.conf"

	case ${CS_OP_MODE} in
		configonly|normal)

			if [ ! -d "${ISOS}" ]; then
				ERRORMSG "El directorio de construcción de imágenes '%s' no existe." "${ISOS}"
				exit 1
			fi

			if [ -f "${TCSCONFFILE}" ]; then
				. "${TCSCONFFILE}"
			else
				ERRORMSG "El archivo de configuraciones '%s' no existe o no es un archivo válido." "${TCSCONFFILE}"
				exit 1
			fi
		;;
	esac

	if ${BIN_DPKG} --compare-versions "${LB_VERSION}" ge 3.0; then
		LB_PARENTS="--parent-mirror-bootstrap=\"${META_REPO}\" \
--parent-mirror-chroot=\"${META_REPO}\" \
--parent-mirror-binary=\"${META_REPO}\" \
--parent-mirror-debian-installer=\"${META_REPO}\" \
--parent-mirror-chroot-security=\"none\" \
--parent-mirror-chroot-volatile=\"none\" \
--parent-mirror-chroot-backports=\"none\" \
--parent-mirror-binary-security=\"none\" \
--parent-mirror-binary-volatile=\"none\" \
--parent-mirror-binary-backports=\"none\""
		LB_INDICES="--apt-indices=\"none\""
		LB_SYSLINUX="--syslinux-theme=\"live-build\""
	else
		LB_INDICES="--binary-indices=\"false\""
		LB_SYSLINUX="--syslinux-menu=\"true\" \
--syslinux-timeout=\"5\" \
--syslinux-splash=\"${IMG_SYSLINUX_SPLASH}\""
		LB_USERNAME="--username=\"${META_DISTRO}\""
		LB_HOSTNAME="--hostname=\"${META_DISTRO}-${SABOR}\""
	fi

	if [ "${IMG_DEBIAN_INSTALLER}" = "live" ]; then
		LB_BOOTAPPEND_INSTALL="--bootappend-install=\"${CS_BOOTAPPEND_INSTALL}\""
	fi

	LB_ARGUMENTS="--architecture=\"${ARCH}\" \
--linux-flavours=\"${KERNEL_ARCH}\" \
--distribution=\"${META_CODENAME}\" \
--mode=\"${META_MODE}\" \
--language=\"${OS_LANG}\" \
--apt=\"aptitude\" \
--apt-recommends=\"false\" \
--apt-secure=\"false\" \
--bootloader=\"syslinux\" \
--binary-images=\"${MEDIO}\" \
--bootstrap=\"debootstrap\" \
--includes=\"none\" \
--archive-areas=\"${META_REPOSECTIONS}\" \
--mirror-bootstrap=\"${META_REPO}\" \
--mirror-chroot=\"${META_REPO}\" \
--mirror-binary=\"${META_REPO}\" \
--mirror-debian-installer=\"${META_REPO}\" \
--mirror-chroot-security=\"none\" \
--mirror-chroot-volatile=\"none\" \
--mirror-chroot-backports=\"none\" \
--mirror-binary-security=\"none\" \
--mirror-binary-volatile=\"none\" \
--mirror-binary-backports=\"none\" \
--security=\"false\" \
--volatile=\"false\" \
--backports=\"false\" \
--source=\"false\" \
--iso-preparer=\"${CS_ISO_PREPARER}\" \
--iso-volume=\"${CS_ISO_VOLUME}\" \
--iso-publisher=\"${CS_ISO_PUBLISHER}\" \
--iso-application=\"${CS_ISO_APPLICATION}\" \
--debian-installer=\"${IMG_DEBIAN_INSTALLER}\" \
--win32-loader=\"false\" \
--memtest=\"none\" \
--bootappend-live=\"${CS_BOOTAPPEND_LIVE}\" \
${LB_BOOTAPPEND_INSTALL} ${LB_PARENTS} ${LB_INDICES} \
${LB_SYSLINUX} ${LB_USERNAME} ${LB_HOSTNAME} \
${LB_QUIET} ${LB_VERBOSE}"

	case ${CS_OP_MODE} in
		configonly|normal)
			WARNINGMSG "Generando árbol de configuraciones ..."
			cd "${ISOS}" && eval "${BIN_LB} config ${LB_ARGUMENTS} 2>&1 | ${BIN_TEE} -a \"${ISOS}/${LOGFILE}\""
			CS_POPULATE_TREE "${ISOS}" "${CS_OP_MODE}" "${CS_PRINT_MODE}"
		;;

		vardump)
			${BIN_ECHO} "${BIN_LB} config ${LB_ARGUMENTS}"
		;;
	esac
}

CS_POPULATE_TREE() {

	# ======================================================================
	# FUNCIÓN: CS_POPULATE_TREE
	# DESCRIPCIÓN: Copia los archivos desde el perfil hasta el árbol de
	#	      configuración.
	# ENTRADAS:
	#       [ISOS]: Directorio donde se encuentra el árbol de configuración.
	#       [CS_OP_MODE]: Modo de operación. 
	#       [CS_PRINT_MODE]: Modo de verbosidad.
	# ======================================================================

	ISOS="${1}"
	[ -n "${ISOS}" ] && shift 1 || true
	CS_OP_MODE="${1}"
	[ -n "${CS_OP_MODE}" ] && shift 1 || true
	CS_PRINT_MODE="${1}"
	[ -n "${CS_PRINT_MODE}" ] && shift 1 || true

	TCSCONFFILE="${ISOS}/config/c-s/tree.conf"

	if [ ! -d "${ISOS}" ]; then
		ERRORMSG "El directorio de construcción de imágenes '%s' no existe." "${ISOS}"
		exit 1
	fi

	if [ -f "${TCSCONFFILE}" ]; then
		. "${TCSCONFFILE}"
	else
		ERRORMSG "El archivo de configuraciones '%s' no existe o no es un archivo válido." "${TCSCONFFILE}"
		exit 1
	fi

	if ${BIN_DPKG} --compare-versions "${LB_VERSION}" ge 3.0; then
		LB_IMG_SYSLINUX_TEMPLATE_DIR="${ISOS}/config/bootloaders/${LB_BOOTLOADER}"
		LB_IMG_SYSLINUX_TEMPLATE_SPLASH_DIR="${ISOS}/config/bootloaders/${LB_BOOTLOADER}"
		LB_IMG_SYSLINUX_SPLASH_DIR="${ISOS}/config/binary_syslinux"
		LB_IMG_INCLUDES_DIR="${ISOS}/config/includes.binary"
		LB_OS_INCLUDES_DIR="${ISOS}/config/includes.chroot"
		LB_IMG_HOOKS_DIR="${ISOS}/config/hooks"
		LB_OS_HOOKS_DIR="${ISOS}/config/hooks"
		LB_OS_EXTRAREPOS_DIR="${ISOS}/config/archives"
		LB_IMG_EXTRAREPOS_DIR="${ISOS}/config/archives"
		LB_OS_EXTRAREPOS_FILE="${LB_OS_EXTRAREPOS_DIR}/sources.list.chroot"
		LB_IMG_EXTRAREPOS_FILE="${LB_IMG_EXTRAREPOS_DIR}/sources.list.binary"
		LB_OS_PACKAGES_DIR="${ISOS}/config/package-lists"
		LB_OS_PACKAGES_FILE="${LB_OS_PACKAGES_DIR}/packages.list.chroot"
		LB_IMG_POOL_PACKAGES_DIR="${ISOS}/config/package-lists"
		LB_IMG_POOL_PACKAGES_FILE="${LB_IMG_POOL_PACKAGES_DIR}/packages.list.binary"
		LB_IMG_DEBIAN_INSTALLER_BANNER_DIR="${ISOS}/config/binary_debian-installer-includes/usr/share/graphics"
		LB_IMG_DEBIAN_INSTALLER_BANNER_FILE="${LB_IMG_DEBIAN_INSTALLER_BANNER_DIR}/logo_debian.png"
		LB_IMG_DEBIAN_INSTALLER_PRESEED_DIR="${ISOS}/config/binary_debian-installer"
		LB_IMG_DEBIAN_INSTALLER_PRESEED_FILE="${LB_IMG_DEBIAN_INSTALLER_PRESEED_DIR}/preseed.cfg"
		LB_IMG_DEBIAN_INSTALLER_GTK_DIR="${ISOS}/config/binary_debian-installer-includes/usr/share/themes/Clearlooks/gtk-2.0"
		LB_IMG_DEBIAN_INSTALLER_GTK_FILE="${LB_IMG_DEBIAN_INSTALLER_GTK_DIR}/gtkrc"
	else
		LB_IMG_SYSLINUX_TEMPLATE_DIR="${ISOS}/config/templates/${LB_BOOTLOADER}"
		LB_IMG_SYSLINUX_TEMPLATE_SPLASH_DIR="${ISOS}/config/templates/${LB_BOOTLOADER}/menu"
		LB_IMG_SYSLINUX_SPLASH_DIR="${ISOS}/config/binary_syslinux"
		LB_IMG_INCLUDES_DIR="${ISOS}/config/binary_local-includes"
		LB_OS_INCLUDES_DIR="${ISOS}/config/chroot_local-includes"
		LB_IMG_HOOKS_DIR="${ISOS}/config/binary_local-hooks"
		LB_OS_HOOKS_DIR="${ISOS}/config/chroot_local-hooks"
		LB_OS_EXTRAREPOS_DIR="${ISOS}/config/chroot_sources"
		LB_IMG_EXTRAREPOS_DIR="${ISOS}/config/chroot_sources"
		LB_OS_EXTRAREPOS_FILE="${LB_OS_EXTRAREPOS_DIR}/sources.chroot"
		LB_IMG_EXTRAREPOS_FILE="${LB_IMG_EXTRAREPOS_DIR}/sources.binary"
		LB_OS_PACKAGES_DIR="${ISOS}/config/chroot_local-packageslists"
		LB_OS_PACKAGES_FILE="${LB_OS_PACKAGES_DIR}/packages.list"
		LB_IMG_POOL_PACKAGES_DIR="${ISOS}/config/binary_local-packageslists"
		LB_IMG_POOL_PACKAGES_FILE="${LB_IMG_POOL_PACKAGES_DIR}/packages.list"
		LB_IMG_DEBIAN_INSTALLER_BANNER_DIR="${ISOS}/config/binary_debian-installer-includes/usr/share/graphics"
		LB_IMG_DEBIAN_INSTALLER_BANNER_FILE="${LB_IMG_DEBIAN_INSTALLER_BANNER_DIR}/logo_debian.png"
		LB_IMG_DEBIAN_INSTALLER_PRESEED_DIR="${ISOS}/config/binary_debian-installer"
		LB_IMG_DEBIAN_INSTALLER_PRESEED_FILE="${LB_IMG_DEBIAN_INSTALLER_PRESEED_DIR}/preseed.cfg"
		LB_IMG_DEBIAN_INSTALLER_GTK_DIR="${ISOS}/config/binary_debian-installer-includes/usr/share/themes/Clearlooks/gtk-2.0"
		LB_IMG_DEBIAN_INSTALLER_GTK_FILE="${LB_IMG_DEBIAN_INSTALLER_GTK_DIR}/gtkrc"
	fi

	${BIN_MKDIR} -p "${LB_IMG_SYSLINUX_TEMPLATE_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_SYSLINUX_TEMPLATE_SPLASH_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_SYSLINUX_SPLASH_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_INCLUDES_DIR}"
	${BIN_MKDIR} -p "${LB_OS_INCLUDES_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_HOOKS_DIR}"
	${BIN_MKDIR} -p "${LB_OS_HOOKS_DIR}"
	${BIN_MKDIR} -p "${LB_OS_EXTRAREPOS_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_EXTRAREPOS_DIR}"
	${BIN_MKDIR} -p "${LB_OS_PACKAGES_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_POOL_PACKAGES_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_DEBIAN_INSTALLER_BANNER_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_DEBIAN_INSTALLER_PRESEED_DIR}"
	${BIN_MKDIR} -p "${LB_IMG_DEBIAN_INSTALLER_GTK_DIR}"

	${BIN_CP} -r ${IMG_SYSLINUX_TEMPLATE}/* "${LB_IMG_SYSLINUX_TEMPLATE_DIR}/"
	${BIN_CP} "${IMG_SYSLINUX_SPLASH}" "${LB_IMG_SYSLINUX_TEMPLATE_SPLASH_DIR}/"
	${BIN_CP} "${IMG_SYSLINUX_SPLASH}" "${LB_IMG_SYSLINUX_SPLASH_DIR}/"

	if [ "${IMG_INCLUDES}" != "none" ]; then
		${BIN_CP} -r ${IMG_INCLUDES}/* "${LB_IMG_INCLUDES_DIR}/"
	fi

	if [ "${OS_INCLUDES}" != "none" ]; then
		${BIN_CP} -r ${OS_INCLUDES}/* "${LB_OS_INCLUDES_DIR}/"
	fi

	if [ "${IMG_HOOKS}" != "none" ]; then
		for IMGHOOK in ${IMG_HOOKS}/*; do
			${BIN_CP} "${IMGHOOK}" "${LB_IMG_HOOKS_DIR}/$( basename "${IMGHOOK}").binary"
		done
	fi

	if [ "${OS_HOOKS}" != "none" ]; then
		for OSHOOK in ${OS_HOOKS}/*; do
			${BIN_CP} "${OSHOOK}" "${LB_OS_HOOKS_DIR}/$( basename "${OSHOOK}").chroot"
		done
	fi

	if [ "${OS_EXTRAREPOS}" != "none" ]; then
		${BIN_CP} "${OS_EXTRAREPOS}" "${LB_OS_EXTRAREPOS_FILE}"
		${BIN_CP} "${OS_EXTRAREPOS}" "${LB_IMG_EXTRAREPOS_FILE}"
	fi

	${BIN_ECHO} "${OS_PACKAGES}" > "${LB_OS_PACKAGES_FILE}"
	${BIN_ECHO} "${IMG_POOL_PACKAGES}" > "${LB_IMG_POOL_PACKAGES_FILE}"

	if [ "${IMG_DEBIAN_INSTALLER}" = "live" ]; then
		${BIN_CP} "${IMG_DEBIAN_INSTALLER_BANNER}" "${LB_IMG_DEBIAN_INSTALLER_BANNER_FILE}"
		${BIN_CP} "${IMG_DEBIAN_INSTALLER_PRESEED}" "${LB_IMG_DEBIAN_INSTALLER_PRESEED_FILE}"
		${BIN_CP} "${IMG_DEBIAN_INSTALLER_GTK}" "${LB_IMG_DEBIAN_INSTALLER_GTK_FILE}"
	fi
}
