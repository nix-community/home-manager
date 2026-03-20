# GPU on non-NixOS systems {#sec-usage-gpu-non-nixos}

To access the GPU, programs need access to OpenGL and Vulkan libraries. While
this works transparently on NixOS, it does not on other Linux systems. There are
two options:

1. Recommended: modify the host system slightly so that the graphics libraries
   can be found where programs from Nixpkgs can find them.
2. Wrap programs from Nixpkgs in an environment which tells them where to find
   graphics libraries.

The first option is very clean because the needed modifications to the host OS
are small. However, it does require root/sudo access to the system, which may
not be available. The second approach avoids that. However, it injects libraries
from Nixpkgs into the environment of wrapped programs, which can make it
impossible to launch programs of the host OS from wrapped programs.


## When sudo is available: fixing the host OS {#sec-usage-gpu-sudo}

The {option}`targets.genericLinux.gpu` module is automatically enabled whenever
the option {option}`targets.genericLinux.enable` is set (unless
[NixGL](#sec-usage-gpu-nosudo) is used instead), which is recommended for
non-NixOS Linux distributions in any case. The module can also be explicitly
enabled by setting {option}`targets.genericLinux.gpu.enable`.

This module builds a directory containing GPU libraries. When activating the
home configuration by `home-manager switch`, the host system is examined: for
compatibility with NixOS, these libraries need to be placed in
`/run/opengl-driver`. If this directory does not exist, or contains a different
set of libraries, the activation script will print a warning such as

```text
Activating checkExistingGpuDrivers
GPU drivers require an update, run
  sudo /nix/store/HASH-non-nixos-gpu/bin/non-nixos-gpu-setup
```

Because the `/run` directory is volatile and disappears on reboot, libraries
cannot be simply copied or linked there. The `non-nixos-gpu-setup` script
installs a Systemd service which ensures that the drivers are linked to
`/run/opengl-driver` on boot. Home Manager will always check and warn you when
this setup needs to be refreshed.

If you ever wish to uninstall these drivers, all you need to do is

```sh
sudo rm /run/opengl-driver
sudo systemctl disable --now non-nixos-gpu.service
sudo rm /etc/systemd/system/non-nixos-gpu.service
```


### GPU offloading {#sec-usage-gpu-offloading}

You can use the {option}`targets.genericLinux.nixGL.prime.installScript` option.
It installs the `prime-offload` script which is configured through options under
{option}`targets.genericLinux.nixGL.prime`. This functionality is independent
from the rest of NixGL and can be used when
{option}`targets.genericLinux.nixGL.packages` is left `null`, which it should be
when using drivers from `/run/opengl-driver`.


### Nvidia drivers {#sec-usage-gpu-nvidia}

If you need to include the proprietary Nvidia drivers, the process is a bit more
involved. You need to:

1. Determine the exact version used by the host system. Example: `550.163.01`

1. Fetch that version of the drivers from Nvidia and calculate their hash.
   Example:

   ```sh
   nix store prefetch-file \
     https://download.nvidia.com/XFree86/Linux-x86_64/550.163.01/NVIDIA-Linux-x86_64-550.163.01.run
   ```

   Attention: the version and architecture are present twice. If you are on an
   ARM system, replace `x86_64` with `aarch64`.

1. Put this information into your home configuration. Example:

   ```nix
   targets.genericLinux.gpu.nvidia = {
     enable = true;
     version = "550.163.01";
     sha256 = "sha256-74FJ9bNFlUYBRen7+C08ku5Gc1uFYGeqlIh7l1yrmi4=";
   };
   ```

::: {.warning}
The Nvidia driver version **must** match the host system. This means that you
must pay attention when upgrading the system and update the home configuration
as well.
:::


## No root access: wrapping programs {#sec-usage-gpu-nosudo}

The wrapping approach is facilitated by
[NixGL](https://github.com/nix-community/nixGL), which can be integrated into
Home Manager.

::: {.warning}

This approach can cause issues when a wrapped program from Nixpkgs executes a
program from the host. For example, Firefox from Nixpkgs must be wrapped by
NixGL in order for graphical acceleration to work. If you then download a PDF
file and open it in a PDF viewer that is not installed from Nixpkgs but is
provided by the host distribution, there may be issues. Because Firefox's
environment injects libraries from NixGL, they are inherited by the PDF viewer,
and unless they are the same or compatible version as the libraries on the host,
the viewer will not work. This problem manifests more often with Vulkan because
it needs a larger set of injected libraries than OpenGL.

The problem typically manifests with errors similar to

```text
/nix/store/HASH-gcc-12.3.0-lib/lib/libstdc++.so.6: version `GLIBCXX_3.4.31' not found
```

:::

To enable the integration, import NixGL into your home configuration, either as
a channel, or as a flake input passed via `extraSpecialArgs`. Then, set the
`targets.genericLinux.nixGL.packages` option to the package set provided by
NixGL.

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
when `targets.genericLinux.nixGL.packages` option is unset, they are no-ops.
This allows them to be used even when the home configuration is used on NixOS
machines. The exception is the `prime-offload` script which ignores
`targets.genericLinux.nixGL.packages` and is installed into the environment
whenever `targets.genericLinux.nixGL.prime.installScript` is set. This script,
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
  targets.genericLinux.nixGL = {
    packages = nixgl.packages;
    defaultWrapper = "mesa";
    offloadWrapper = "nvidiaPrime";
    installScripts = [ "mesa" "nvidiaPrime" ];
  };

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
  targets.genericLinux.nixGL.packages = import <nixgl> { inherit pkgs; };
  # The rest is the same as above
  ...
```
