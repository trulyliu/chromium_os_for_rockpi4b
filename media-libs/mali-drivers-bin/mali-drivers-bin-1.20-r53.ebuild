# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_REPO=("https://github.com/trulyliu")
CROS_WORKON_COMMIT=("7efa0cbda27a6e775c35339241fd864b56da107c")
CROS_WORKON_TREE=("517a1f30f687aac6aa7ffeb567a983ce3501c712")
CROS_WORKON_EGIT_BRANCH="master"
CROS_WORKON_BLACKLIST=1
CROS_WORKON_PROJECT=("rockpi4b_mali_drivers")
CROS_WORKON_SRCPATH=("")
CROS_WORKON_LOCALNAME=("${PN}")
CROS_WORKON_OUTOFTREE_BUILD=0
if [[ "${PV}" == "9999" ]] ; then
    CROS_WORKON_ALWAYS_LIVE="1"
fi

DEPEND=""
RDEPEND="${DEPEND}"

LICENSE="Google-TOS"
SLOT="0"
KEYWORDS="-* arm64 arm"

DEPEND="
	x11-drivers/opengles-headers
	"

RDEPEND="
	!media-libs/mali-drivers
	!x11-drivers/opengles
	x11-libs/libdrm
	"
# workaround cross_src_unpack always checkout empty source
EGIT_BOOTSTRAP='git clean -dfx; git reset --hard; git checkout -f;'


# This must be inherited *after* EGIT/CROS_WORKON variables defined
inherit cros-workon

src_configure() {
    info "src_configure"
}

src_compile() {
    info "src_compile"
}

src_install() {
    dolib.so aarch64/usr/lib64/libMali.so.14.0
    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so.1
    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so.1.0.0
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv1_CM.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so.2
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so.2.0.0
    dosym libMali.so.14.0 /usr/$(get_libdir)/libMali.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libMali.so.14
    dosym libMali.so.14.0 /usr/$(get_libdir)/libMaliOpenCL.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libOpenCL.so
#    dosym libMali.so.14.0 /usr/$(get_libdir)/libgbm.so.1
#    dosym libMali.so.14.0 /usr/$(get_libdir)/libgbm.so.1.0.0

    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so.2
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so.2.1.20
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv2.so

    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so.1
    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so.1.1.20
    dosym libMali.so.14.0 /usr/$(get_libdir)/libEGL.so

    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv1_CM.so.1.1.20
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv1_CM.so
    dosym libMali.so.14.0 /usr/$(get_libdir)/libGLESv1_CM.so.1

    dosym libMali.so.14.0 /usr/$(get_libdir)/libmali.so.0.1.20
    dosym libMali.so.14.0 /usr/$(get_libdir)/libmali.so.0
    dosym libMali.so.14.0 /usr/$(get_libdir)/libmali.so

}