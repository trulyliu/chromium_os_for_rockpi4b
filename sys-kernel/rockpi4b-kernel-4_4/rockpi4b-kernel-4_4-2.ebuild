# Copyright 2017 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_REPO=("https://github.com/radxa" "https://github.com/trulyliu")
CROS_WORKON_COMMIT=("cc4fef39f29bda97ba1d9129d897e77d08ccf096" "1b0344194b1ea807f3c851974f865f25d6cf0f0c")
CROS_WORKON_TREE=("e47d7d618993afdbb7e513478ad4b280ed6636c0" "11273ba283496c4205d6fd1d39a0b8a08059708f")
CROS_WORKON_EGIT_BRANCH="release-4.4-rockpi4"
CROS_WORKON_BLACKLIST=1
CROS_WORKON_PROJECT=("kernel" "rockpi4b_toolchain")
CROS_WORKON_SRCPATH=("" "")
TOOLCHAIN_DESTDIR="${S}/toolchain"
TOOLCHAIN_NAME="gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu"
CROS_WORKON_DESTDIR=("${S}" "${TOOLCHAIN_DESTDIR}")
CROS_WORKON_LOCALNAME=("${PN}" "toolchain")
CROS_WORKON_OUTOFTREE_BUILD=0
if [[ "${PV}" == "9999" ]] ; then
    CROS_WORKON_ALWAYS_LIVE="1"
fi

DEPEND=""
RDEPEND="${DEPEND}"

# workaround cross_src_unpack always checkout empty source
EGIT_BOOTSTRAP='git clean -dfx; git reset --hard; git checkout -f;'

# AFDO_PROFILE_VERSION is the build on which the profile is collected.
# This is required by kernel_afdo.
#
# TODO: Allow different versions for different CHROMEOS_KERNEL_SPLITCONFIGs
AFDO_PROFILE_VERSION="R74-11803.0-1551697383"

EPATCH_SOURCE=${FILESDIR}

# Put it here insread of make.conf to avoid chromeos-kernel-4_4 fail to compile
CHROMEOS_KERNEL_CONFIG="arch/arm64/configs/rockchip_linux_defconfig"

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

kmake() {
	elog "============override kmake in cros-kernel2========="
	local wifi_version
	local v

	# Allow override of kernel arch.
	local kernel_arch=${CHROMEOS_KERNEL_ARCH:-$(tc-arch-kernel)}

	# Support 64bit kernels w/32bit userlands.
	local cross=${CHOST}
	case ${ARCH}:${kernel_arch} in
		x86:x86_64)
			cross="x86_64-cros-linux-gnu"
			;;
		arm:arm64)
			cross="aarch64-cros-linux-gnu"
			;;
	esac

	if [[ "${CHOST}" != "${cross}" ]]; then
		unset CC CXX LD STRIP OBJCOPY
	fi

	tc-export_build_env BUILD_{CC,CXX}
	if use clang; then
		CHOST=${cross} clang-setup-env
	fi

	set -- \
		HOSTCC="${BUILD_CC}" \
		HOSTCXX="${BUILD_CXX}" \
		"$@"

	local kcflags="${KCFLAGS}"

	local indirect_branch_options_v1=(
		"-mindirect-branch=thunk"
		"-mindirect-branch-loop=pause"
		"-fno-jump-tables"
	)
	local indirect_branch_options_v2=(
		"-mindirect-branch=thunk"
		"-mindirect-branch-register"
	)

	# LLVM needs this to parse perf.data.
	# See AutoFDO README for details: https://github.com/google/autofdo
#	use clang && kcflags+=" -fdebug-info-for-profiling "

	# The kernel doesn't use CFLAGS and doesn't expect it to be passed
	# in.  Let's be explicit that it won't do anything by unsetting CFLAGS.
	#
	# In general the kernel manages its own tools flags and doesn't expect
	# someone external to pass flags in unless those flags have been
	# very specifically tailored to interact well with the kernel Makefiles.
	# In that case we pass in flags with KCFLAGS which is documented to be
	# not a full set of flags but as "additional" flags. In general the
	# kernel Makefiles carefully adjust their flags in various
	# sub-directories to get the needed result.  The kernel has CONFIG_
	# options for adjusting compiler flags and self-adjusts itself
	# depending on whether it detects clang or not.
	#
	# In the same spirit, let's also unset LDFLAGS.  While (in some cases)
	# the kernel will build upon LDFLAGS passed in from the environment it
	# makes sense to just let the kernel be like we do for the rest of the
	# flags.
	unset CFLAGS
	unset LDFLAGS

	ARCH=${kernel_arch} \
		KCFLAGS="${kcflags}" \
		emake \
		CROSS_COMPILE="${TOOLCHAIN_DESTDIR}/${TOOLCHAIN_NAME}/bin/aarch64-linux-gnu-" \
		O="$(cros-workon_get_build_dir)" \
		"$@"
}

src_unpack() {
	cros-workon_src_unpack
}

#src_prepare() {
#	EPATCH_FORCE="yes"
#        EPATCH_SOURCE="${FILESDIR}"
#        EPATCH_SUFFIX="patch"
#	epatch
#}

src_configure() {
        # Required for building uImage
        export LOADADDR=0x2000000
        cros-kernel2_src_configure
}


kernelrelease() {
        kmake -s --no-print-directory kernelrelease
}


overlay_dtb_install() {
    local version=$(kmake -s --no-print-directory kernelrelease)
    local KBD=$(cros-workon_get_build_dir)

    info "Create ${KBD}/hw_intfc.conf"
    cat > ${KBD}/hw_intfc.conf <<EOF
intfc:uart2=on
intfc:uart4=on
intfc:dtoverlay=console-on-ttyS2
intfc:dtoverlay=two-color-led

EOF

    info "Install /boot/hw_intfc.conf"
    insinto "/boot"
    doins ${KBD}/hw_intfc.conf

    info "Install /boot/overlays"
    dodir "/boot/overlays"
    insinto "/boot/overlays"
    for dtbo in ${KBD}/arch/arm64/boot/dts/rockchip/overlays/*.dtbo ;
    do
        doins "${dtbo}"
    done
}

src_install() {

    local version=$(kmake -s --no-print-directory kernelrelease)
    cros-kernel2_src_install

    local KBD=$(cros-workon_get_build_dir)
    local dtb="rockpi-4b-linux.dtb"
    info "Install /boot/Image-${version}"
    insinto "/boot"
    newins ${KBD}/arch/arm64/boot/Image Image-${version}

    info "Install /boot/dts/${dtb}"
    dodir "/boot/dts"
    insinto "/boot/dts"
    doins "${KBD}/arch/arm64/boot/dts/rockchip/${dtb}"

    info "Create ${KBD}/extlinux.conf"
    cat > ${KBD}/extlinux.conf <<EOF
menu title Boot Menu
default kernel-4.4
timeout 20

label kernel-4.4
    kernel /Image-${version}
    fdt /dts/${dtb}
    append  earlyprintk console=ttyS2,1500000n8 rw root=/dev/mmcblk0p3 rootfstype=ext4 init=/sbin/init rootwait cros_debug loglevel=7

label kernel-4.4-ro
    kernel /Image-${version}
    fdt /dts/${dtb}
    append  earlyprintk console=ttyS2,1500000n8 ro root=/dev/mmcblk0p3 rootfstype=ext4 init=/sbin/init rootwait cros_debug loglevel=7

EOF

    info "Install /boot/extlinux/extlinux.conf"
    dodir "/boot/extlinux"
    insinto "/boot/extlinux"
    doins "${KBD}/extlinux.conf"

    unlink '{D}'/boot/zImage >/dev/null 2>&1 || true

    overlay_dtb_install
}
