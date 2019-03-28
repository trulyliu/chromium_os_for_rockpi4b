# Copyright 2016 The Chromium OS Authors. All rights reserved.
# Distributed under the terms of the GNU General Public License v2

EAPI=5

CROS_WORKON_REPO=("https://github.com/trulyliu")
CROS_WORKON_COMMIT=("30a072b7bc8f2b57995c9ba3b8a15c3260838cc7")
CROS_WORKON_TREE=("4f45fece44206503f47624b2ae468b968d19adc8")
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

DEPEND=""
RDEPEND=""
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
    dodir "/system"
    insinto "/system"
    pushd "${S}/firmware/system"
    doins -r "etc"
    doins -r "vendor"
}