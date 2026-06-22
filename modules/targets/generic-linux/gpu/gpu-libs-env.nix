{
  lib,
  buildEnv,
  mesa,
  libglvnd,
  libvdpau-va-gl,
  intel-media-driver,
  nvidia-vaapi-driver,
  linuxPackages,
  system,
  nvidia_x11 ? linuxPackages.nvidia_x11,
  addNvidia ? false,
  egl-wayland,
  egl-wayland2,
  egl-gbm,
}:

buildEnv {
  name = "non-nixos-gpu";
  paths = [
    mesa
    libglvnd
    libvdpau-va-gl
  ]
  ++ lib.optional (system == "x86_64-linux") intel-media-driver
  ++ lib.optionals addNvidia [
    nvidia_x11
    nvidia-vaapi-driver
    egl-wayland
    egl-wayland2
    egl-gbm
  ];
}
