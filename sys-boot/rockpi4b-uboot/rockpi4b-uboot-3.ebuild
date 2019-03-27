# Copyright 2018 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=6

CROS_WORKON_REPO=("https://github.com/radxa" "https://github.com/rockchip-linux" "https://github.com/trulyliu")
CROS_WORKON_COMMIT=("b0bb5ac45db82b27dd7dbad0c14f1e96ca657815" "9fc33aee92908b538ca6687550be437415efae8e" "1b0344194b1ea807f3c851974f865f25d6cf0f0c")
CROS_WORKON_TREE=("7f6a2509d56b6d0edcd2e878fc0ca92732ee1aa6" "fa6123a12ef531a46cdac86eb8ca94fe67ed336d" "11273ba283496c4205d6fd1d39a0b8a08059708f")
CROS_WORKON_PROJECT=("u-boot" "rkbin" "rockpi4b_toolchain")
CROS_WORKON_SRCPATH=("" "" "")
RKBIN_DESTDIR="${S}/rkbin"
UBOOT_DESTDIR="${S}/uboot"
TOOLCHAIN_DESTDIR="${S}/toolchain"
TOOLCHAIN_NAME="gcc-linaro-7.4.1-2019.02-x86_64_aarch64-linux-gnu"
CROS_WORKON_DESTDIR=("${UBOOT_DESTDIR}" "${RKBIN_DESTDIR}" "${TOOLCHAIN_DESTDIR}")
CROS_WORKON_LOCALNAME=("${PN}" "rkbin" "toolchain")
CROS_WORKON_BLACKLIST=1
if [[ "${PV}" == "9999" ]] ; then
    CROS_WORKON_ALWAYS_LIVE="1"
fi

# workaround cross_src_unpack always checkout empty source
EGIT_BOOTSTRAP='git clean -dfx; git reset --hard; git checkout -f;'

inherit toolchain-funcs flag-o-matic cros-workon

DESCRIPTION="Das U-Boot boot loader"
HOMEPAGE="http://www.denx.de/wiki/U-Boot"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="-* arm64 arm"
IUSE="dev werror"
RESTRICT="mirror"

DEPEND=""

RDEPEND="${DEPEND}
	chromeos-base/u-boot-scripts
	!!sys-boot/chromeos-u-boot
	"

UB_BUILD_DIR="build"
UB_BUILD_ABS_DIR="${UBOOT_DESTDIR}/${UB_BUILD_DIR}"
ROCKPI_UBOOT_IMG='rockpi-uboot.img'


# @FUNCTION: get_current_u_boot_config
# @DESCRIPTION:
# Finds the config for the current board by checking the master configuration.
get_current_u_boot_config() {
    echo rock-pi-4b-rk3399
}

umake() {
	# Add `ARCH=` to reset ARCH env and let U-Boot choose it.
	ARCH= emake "${COMMON_MAKE_FLAGS[@]}" "$@"
}

get_file_path() {
	find $1 -name "$2" |sort -r |sed -n '1p'
}

src_configure() {
	pushd ${UBOOT_DESTDIR}
        export LDFLAGS=$(raw-ldflags)
        tc-export BUILD_CC

        config="$(get_current_u_boot_config)"
        [[ -n "${config}" ]] || die "No U-Boot config selected"
        elog "Using U-Boot config: ${config}"

        local CROSS_PREFIX="${TOOLCHAIN_DESTDIR}/${TOOLCHAIN_NAME}/bin/aarch64-linux-gnu-"

        #DEV_TREE_SEPARATE=1
        COMMON_MAKE_FLAGS=(
                "CROSS_COMPILE=${CROSS_PREFIX}"
                "HOSTCC=${BUILD_CC}"
                HOSTSTRIP=true
                QEMU_ARCH=
        )
        if use dev; then
                # Avoid hiding the errors and warnings
                COMMON_MAKE_FLAGS+=(
                        -s
                        QUIET=1
                )
        else
                COMMON_MAKE_FLAGS+=(
                        -k
                )
        fi
        use werror && COMMON_MAKE_FLAGS+=( WERROR=y )
	        BUILD_FLAGS=(
                "O=${UB_BUILD_DIR}"
        )
        umake "${BUILD_FLAGS[@]}" distclean
        umake "${BUILD_FLAGS[@]}" "${config}_defconfig"
	popd
}

img_pack() {
    local RKBL_DDR800_BIN=$(get_file_path ${RKBIN_DESTDIR} 'rk3399_ddr_800MHz_v*.bin')
    local RKBL_MINILOADER_BIN=$(get_file_path ${RKBIN_DESTDIR} 'rk3399_miniloader_v*.bin')
	local RKBL31_ELF=$(get_file_path ${RKBIN_DESTDIR} 'rk3399_bl31_v*.elf')
	pushd ${UB_BUILD_ABS_DIR}

	# We use rockchip mini loader rather than spl loader
	# 1. create idloader
	${UB_BUILD_ABS_DIR}/tools/mkimage -n rk3399 -T rksd -d ${RKBL_DDR800_BIN} idbloader.img die || "fail create idbloader.img"
	cat ${RKBL_MINILOADER_BIN} >> idbloader.img || die "fail concat miniloader with idbloader.img"
	# 2. create trust.img
        cat >trust.ini <<EOF
[VERSION]
MAJOR=1
MINOR=0
[BL30_OPTION]
SEC=0
[BL31_OPTION]
SEC=1
PATH=${RKBL31_ELF}
ADDR=0x10000
[BL32_OPTION]
SEC=0
[BL33_OPTION]
SEC=0
[OUTPUT]
PATH=trust.img
EOF
	${RKBIN_DESTDIR}/tools/trust_merger ./trust.ini
	# 3. create uboot.img
	${RKBIN_DESTDIR}/tools/loaderimage --pack --uboot u-boot-dtb.bin uboot.img 0x200000 || die "fail to create uboot.img"
	# 4. concatinate idbloader.img uboot.img and trust.img
	fallocate -l 10M ${ROCKPI_UBOOT_IMG} || die "fail to allocate ${ROCKPI_UBOOT_IMG} "
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 40" |bc` if=idbloader.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd idbloader.img"
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 4000" |bc` if=uboot.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd uboot.img"
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 6000" |bc` if=trust.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd trust.img"
	popd
}

src_compile() {
	pushd ${UBOOT_DESTDIR}
	local RKBL31_ELF=$(get_file_path ${RKBIN_DESTDIR} 'rk3399_bl31_v*.elf')
	mkdir -p ${UB_BUILD_ABS_DIR}
	ln -f ${RKBL31_ELF} ${UB_BUILD_ABS_DIR}/bl31.elf || die "Can not create bl31.elf" 
	umake "${BUILD_FLAGS[@]}"
	umake "${BUILD_FLAGS[@]}" u-boot.itb
	popd
	img_pack
}

src_install() {
	# Install boot loader image
	insinto "/boot"
	doins ${UB_BUILD_ABS_DIR}/${ROCKPI_UBOOT_IMG}
}
