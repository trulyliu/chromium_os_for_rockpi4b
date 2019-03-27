EAPI=5

DESCRIPTION="Rockpi4b BSP package (meta package to pull in driver/tool dependencies)"

LICENSE="BSD-Google"
SLOT="0"
KEYWORDS="-* arm64 arm"

RDEPEND="
    sys-boot/rockpi4b-uboot
    sys-kernel/rockpi4b-kernel-4_4
    >=chromeos-base/tty-0.0.1-r99
    >=chromeos-base/chromeos-bsp-baseboard-gru-0.0.3
"

DEPEND="${RDEPEND}"

