# Copyright 2019 The Chromium OS Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file.

install_rockpi_bootloader() {
  local image="$1"
  local efi_offset_sectors=$(partoffset "$1" 12)
  local efi_size_sectors=$(partsize "$1" 12)
  local efi_offset=$(( efi_offset_sectors * 512 ))
  local efi_size=$(( efi_size_sectors * 512 ))
  local efi_dir=$(mktemp -d)

  sudo mount -o loop,offset=${efi_offset},sizelimit=${efi_size} "$1" \
    "${efi_dir}"

  info "Installing uboot firmware on ${image}"
  sudo dd conv=notrunc,fsync bs=512 seek=`echo "ibase=16; 40" |bc`  skip=`echo "ibase=16; 40" |bc` if=${ROOT}/boot/rockpi-uboot.img of=${image} || die "fail to install uboot fireware"

  info "Installing kernel"
  sudo cp "${ROOT}/boot/Image-"* "${efi_dir}/" || die "fail to install kernel"
  sudo cp "${ROOT}/boot/config-"* "${efi_dir}/" || die "fail to install kernel"
  sudo cp "${ROOT}/boot/System.map-"* "${efi_dir}/" || die "fail to install kernel"

  info "Installing dts"
  sudo mkdir -p ${efi_dir}/dts/
  sudo cp "${ROOT}/boot/dts/"*.dtb "${efi_dir}/dts/" || die "fail to install dts"

  info "Creating extlinux configuration files"
  sudo mkdir -p ${efi_dir}/extlinux/
  sudo cp "${ROOT}/boot/extlinux/extlinux.conf" "${efi_dir}/extlinux/" || die "fail to install extlinux configuration files"

  info "Install dtb overlays"
  [ -d "${ROOT}/boot/overlays" ] && sudo cp -a "${ROOT}/boot/overlays" "${efi_dir}/"
  [ -f "${ROOT}/boot/hw_intfc.conf" ] && sudo cp "${ROOT}/boot/hw_intfc.conf" "${efi_dir}/"

  sudo umount "${efi_dir}"
  rmdir "${efi_dir}"
}

board_setup() {
  install_rockpi_bootloader "$1"
}
