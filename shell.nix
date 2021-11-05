{ pkgs ? import <nixpkgs> {} }:

with pkgs;

stdenv.mkDerivation {
  name = "terraform-packer-opennebula-example-env";
  buildInputs = [
    git
    cdrkit cloud-utils
    libvirt libxslt
    pkgconfig gnumake
    go gcc
  ];
}
