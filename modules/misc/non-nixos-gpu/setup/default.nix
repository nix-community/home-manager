# SPDX-FileCopyrightText: 2025 Jure Varlec <jure@varlec.si>
#
# SPDX-License-Identifier: MIT

{
  lib,
  stdenv,
  non-nixos-gpu-env,
}:

stdenv.mkDerivation {
  name = "non-nixos-gpu";

  meta = {
    description = "GPU driver setup for Nix on non-NixOS Linux systems";
    homepage = "https://github.com/exzombie/non-nixos-gpu";
    license = lib.licenses.mit;
    mainProgram = "non-nixos-gpu-setup";
  };

  src = ./.;
  patchPhase = ''
    substituteInPlace non-nixos-gpu* \
      --replace '@@resources@@' "$out/resources" \
      --replace '@@env@@' "${non-nixos-gpu-env}"
  '';
  installPhase = ''
    mkdir -p $out/{bin,resources}
    cp non-nixos-gpu-setup $out/bin
    cp non-nixos-gpu.service $out/resources
  '';
}
