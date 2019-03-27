# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

DESCRIPTION="chromeos kernel dummy package"
HOMEPAGE="https://www.chromium.org/chromium-os/chromiumos-design-docs/chromium-os-kernel"
DESCRIPTION="Chrome OS Linux Kernel 4.4"
KEYWORDS="*"

SLOT="0"

inherit cros-workon

DEPEND=""
RDEPEND=""

S=${WORKDIR}

src_install() {
    echo "hello rockpi"
}

src_unpack() {
    echo "unpack"
}

src_configure() {
    echo "configure"
}

src_compile() {
    echo "compile"
}

