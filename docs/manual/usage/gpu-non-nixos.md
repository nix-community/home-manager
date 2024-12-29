# GPU on non-NixOS systems {#sec-usage-gpu-non-nixos}

To access the GPU, programs need access to OpenGL and Vulkan libraries. While
this works transparently on NixOS, it does not on other Linux systems. A
solution is provided by [NixGL](https://github.com/nix-community/nixGL), which
can be integrated into Home Manager.

To enable the integration, import NixGL into your home configuration, either as
a channel, or as a flake input passed via `extraSpecialArgs`. Then, set the
`nixGL.packages` option to the package set provided by NixGL.

Once integration is enabled, it can be used in two ways: as Nix functions for
wrapping programs installed via Home Manager, and as shell commands for running
programs installed by other means (such as `nix shell`). In either case, there
are several wrappers available. They can be broadly categorized

- by vendor: as Mesa (for Free drivers of all vendors) and Nvidia (for
  Nvidia-specific proprietary drivers).
- by GPU selection: as primary and secondary (offloading).

For example, the `mesa` wrapper provides support for running programs on the
primary GPU for Intel, AMD and Nouveau drivers, while the `mesaPrime` wrapper
does the same for the secondary GPU.

**Note:** when using Nvidia wrappers together with flakes, your home
configuration will not be pure and needs to be built using `home-manager switch
--impure`. Otherwise, the build will fail, complaining about missing attribute
`currentTime`.

Wrapper functions are available under `config.lib.nixGL.wrappers`. However, it
can be more convenient to use the `config.lib.nixGL.wrap` alias, which can be
configured to use any of the wrappers. It is intended to provide a customization
point when the same home configuration is used across several machines with
different hardware. There is also the `config.lib.nixGL.wrapOffload` alias for
two-GPU systems.

Another convenience is that all wrapper functions are always available. However,
when `nixGL.packages` option is unset, they are no-ops. This allows them to be
used even when the home configuration is used on NixOS machines. The exception
is the `prime-offload` script which ignores `nixGL.packages` and is installed
into the environment whenever `nixGL.prime.installScript` is set. This script,
which can be used to start a program on a secondary GPU, does not depend on
NixGL and is useful on NixOS systems as well.

Below is an abbreviated example for an Optimus laptop that makes use of both
Mesa and Nvidia wrappers, where the latter is used in dGPU offloading mode. It
demonstrates how to wrap `mpv` to run on the integrated Intel GPU, wrap FreeCAD
to run on the Nvidia dGPU, and how to install the wrapper scripts. It also wraps
Xonotic to run on the dGPU, but uses the wrapper function directly for
demonstration purposes.

```nix
{ config, lib, pkgs, nixgl, ... }:
{
  nixGL.packages = nixgl.packages;
  nixGL.defaultWrapper = "mesa";
  nixGL.offloadWrapper = "nvidiaPrime";
  nixGL.installScripts = [ "mesa" "nvidiaPrime" ];

  programs.mpv = {
    enable = true;
    package = config.lib.nixGL.wrap pkgs.mpv;
  };

  home.packages = [
    (config.lib.nixGL.wrapOffload pkgs.freecad)
    (config.lib.nixGL.wrappers.nvidiaPrime pkgs.xonotic)
  ];
}
```

The above example assumes a flake-based setup where `nixgl` was passed from the
flake. When using channels, the example would instead begin with

```nix
{ config, lib, pkgs, ... }:
{
  nixGL.packages = import <nixgl> { inherit pkgs; };
  # The rest is the same as above
  ...
```
