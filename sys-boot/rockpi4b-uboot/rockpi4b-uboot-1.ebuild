EAPI=4

EGIT_BRANCH="master"
EGIT_REPO_URI="git://git.denx.de/u-boot.git"
EGIT_COMMIT="2e8092d94f40a5692baf3ec768ce3216a7bf032a"
#CROS_WORKON_BLACKLIST="1"
EGIT_BOOTSTRAP='git checkout -f'
# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit git-2

# http://opensource.rock-chips.com/wiki_Boot_option
# http://opensource.rock-chips.com/wiki_Partitions

DESCRIPTION="U-Boot boot laoder For RockPi4b Board"
HOMEPAGE="http://git.denx.de/u-boot.git"
KEYWORDS="-* arm64 arm"
SLOT="0"
LICENSE="GPL-2"

DEPEND=""
RDEPEND="${DEPEND}"

RKBL_URI='https://github.com/rockchip-linux/rkbin/raw/master/bin/rk33/rk3399_bl31_v1.25.elf'
RKBL31_VER='v1.25'
RKBL_DDR800_VER='v1.19'
RKBL_MINILOADER_VER='v1.18'

#Don't change this
RKBL31_FILENAME='bl31.elf'

ROCKPI_UBOOT_IMG='rockpi-uboot.img'

umake() {
        env ARCH=arm64 CHIP=rk3399 emake CROSS_COMPILE="/toolchain/gcc-linaro-7.4.1/bin/aarch64-linux-gnu-" "$@"
}

src_unpack() {
	# Call git-2_src_unpack directly because cros-workon_src_unpack
	# would override EGIT_REPO_URI as CROS_GIT_HOST_URL, that is
	# https://chromium.googlesource.com
	git-2_src_unpack

}

src_prepare() {
	#curl -L ${RKBL_URI} -o ${S}/${RKBL31_FILENAME} || die "Can not get bl31"
	cp ${FILESDIR}/rk3399_bl31_${RKBL31_VER}.elf ${S}/${RKBL31_FILENAME} || die "Can not copy bl31.efi"
}

src_configure() {
	umake evb-rk3399_defconfig
}

src_compile() {
	umake
	umake u-boot.itb

	# We use rockchip mini loader rather than spl loader
	# 1. create idloader
	./tools/mkimage -n rk3399 -T rksd -d ${FILESDIR}/rk3399_ddr_800MHz_${RKBL_DDR800_VER}.bin idbloader.img die "fail create idbloader.img"
	cat ${FILESDIR}/rk3399_miniloader_${RKBL_MINILOADER_VER}.bin >> idbloader.img || die "fail concat miniloader with idbloader.img"
	# 2. create trust.img
    cat >trust.ini <<EOF
[VERSION]
MAJOR=1
MINOR=0
[BL30_OPTION]
SEC=0
[BL31_OPTION]
SEC=1
PATH=${RKBL31_FILENAME}
ADDR=0x10000
[BL32_OPTION]
SEC=0
[BL33_OPTION]
SEC=0
[OUTPUT]
PATH=trust.img
EOF
	${FILESDIR}/tools/trust_merger ${S}/trust.ini
	# 3. create uboot.img
	${FILESDIR}/tools/loaderimage --pack --uboot u-boot-dtb.bin uboot.img 0x200000 || die "fail to create uboot.img"
	# 4. concatinate idbloader.img uboot.img and trust.img
	fallocate -l 10M ${ROCKPI_UBOOT_IMG} || die "fail to allocate ${ROCKPI_UBOOT_IMG} "
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 40" |bc` if=idbloader.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd idbloader.img"
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 4000" |bc` if=uboot.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd uboot.img"
	dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 6000" |bc` if=trust.img of=${ROCKPI_UBOOT_IMG}  || die "fail to dd trust.img"
	sync
}

src_install() {
	# Install boot loader image
	insinto "/boot"
	doins ${S}/${ROCKPI_UBOOT_IMG}

	# Install configuration file
	insinto "/boot/extlinux"
	doins ${FILESDIR}/extlinux.conf
}

