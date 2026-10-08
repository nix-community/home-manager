{
  lib,
  stdenv,
  nixStateDirectory,
  nonNixosGpuEnv,
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
      --replace-quiet '@@resources@@' "$out/resources" \
      --replace-quiet '@@statedir@@' '${nixStateDirectory}' \
      --replace-quiet '@@tmpfilesdir@@' "$out/lib/tmpfiles.d" \
      --replace-quiet '@@env@@' "${nonNixosGpuEnv}"
  '';
  installPhase = ''
    mkdir -p $out/{bin,resources,lib/tmpfiles.d}
    cp non-nixos-gpu-setup $out/bin
    cp non-nixos-gpu.conf $out/lib/tmpfiles.d

    # Add Nvidia EGL config, when present
    if [[ -d "${nonNixosGpuEnv}/share/egl/egl_external_platform.d" ]]; then
      for path in "${nonNixosGpuEnv}/share/egl/egl_external_platform.d"/*; do
        fname=$(basename "$path")
        dstname=''${fname%.json}_nix_gpu.json
        echo "L+ /etc/egl/egl_external_platform.d/$dstname - - - - $path" \
          >> $out/lib/tmpfiles.d/non-nixos-gpu.conf
      done
    fi
  '';
}
