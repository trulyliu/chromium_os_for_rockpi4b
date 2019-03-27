# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5
CROS_WORKON_PROJECT="chromiumos/third_party/kernel"
CROS_WORKON_LOCALNAME="kernel/v4.4"
CROS_WORKON_COMMIT=("ac02120c0d3ecf66575e189dde0da00515fee49b")
CROS_WORKON_TREE=("13069268f79fe13c1ae934b663f89a65e3846db1")
CROS_WORKON_OUTOFTREE_BUILD=0
if [[ "${PV}" == "9999" ]] ; then
    CROS_WORKON_ALWAYS_LIVE="1"
fi

DEPEND=""
RDEPEND="${DEPEND}"

# AFDO_PROFILE_VERSION is the build on which the profile is collected.
# This is required by kernel_afdo.
#
# TODO: Allow different versions for different CHROMEOS_KERNEL_SPLITCONFIGs
AFDO_PROFILE_VERSION="R74-11803.0-1551697383"

EPATCH_SOURCE=${FILESDIR}

# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon cros-kernel2

HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Chrome OS Linux Kernel 4.4"
KEYWORDS="-* arm64 arm"

# Change the following (commented out) number to the next prime number
# when you change "cros-kernel2.eclass" to work around http://crbug.com/220902
#
# NOTE: There's nothing magic keeping this number prime but you just need to
# make _any_ change to this file.  ...so why not keep it prime?
#
# Don't forget to update the comment in _all_ chromeos-kernel-x_x-9999.ebuild
# files (!!!)
#
# The coolest prime number is: 47

src_unpack() {
	cros-workon_src_unpack
}

src_prepare() {
	EPATCH_FORCE="yes"
        EPATCH_SOURCE="${FILESDIR}"
        EPATCH_SUFFIX="patch"
	epatch
}

src_configure() {
        # Required for building uImage
        export LOADADDR=0x2000000
        cros-kernel2_src_configure
}

src_install() {
    local version=$(kmake -s --no-print-directory kernelrelease)
    cros-kernel2_src_install

    local KBD=$(cros-workon_get_build_dir)
    local dtb="rk3399-rockpi4b.dtb"
    insinto "/boot"
    newins ${KBD}/arch/arm64/boot/Image Image-${version}

    dodir "/boot/dts"
    insinto "/boot/dts"
    doins ${KBD}/arch/arm64/boot/dts/rockchip/${dtb}

    cat > ${KBD}/extlinux.conf <<EOF
menu title Boot Menu
default kernel-4.4
timeout 20

label kernel-4.4
    kernel /Image-${version}
    fdt /dts/${dtb}
    append  earlyprintk=ttyS2,1500000n8 console=ttyS2,1500000n8 rw root=/dev/mmcblk0p3 rootfstype=ext4 init=/sbin/init rootwait cros_debug loglevel=7

label kernel-4.4-ro
    kernel /dts/Image-${version}
    fdt /${dtb}
    append  earlyprintk=ttyS2,1500000n8 console=ttyS2,1500000n8 ro root=/dev/mmcblk0p3 rootfstype=ext4 init=/sbin/init rootwait cros_debug loglevel=7
EOF

    dodir "/boot/extlinux"
    insinto "/boot/extlinux"
    doins ${KBD}/extlinux.conf

    unlink '{D}'/boot/zImage >/dev/null 2>&1 || true

}
