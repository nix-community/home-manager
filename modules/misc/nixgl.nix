{ config, lib, pkgs, ... }:

let
  cfg = config.nixGL;
  wrapperListMarkdown = with builtins;
    foldl' (list: name:
      list + ''
        - ${name}
      '') "" (attrNames config.lib.nixGL.wrappers);
in {
  meta.maintainers = [ lib.maintainers.smona ];

  options.nixGL = {
    packages = lib.mkOption {
      type = with lib.types; nullOr attrs;
      default = null;
      example = lib.literalExpression "inputs.nixGL.packages";
      description = ''
        The nixGL package set containing GPU library wrappers. This can be used
        to provide OpenGL and Vulkan access to applications on non-NixOS systems
        by using `(config.lib.nixGL.wrap <package>)` for the default wrapper, or
        `(config.lib.nixGL.wrappers.<wrapper> <package>)` for any available
        wrapper.

        The wrapper functions are always available. If this option is empty (the
        default), they are a no-op. This is useful on NixOS where the wrappers
        are unnecessary.

        Note that using any Nvidia wrapper requires building the configuration
        with the `--impure` option.
      '';
    };

    defaultWrapper = lib.mkOption {
      type = lib.types.enum (builtins.attrNames config.lib.nixGL.wrappers);
      default = "mesa";
      description = ''
        The package wrapper function available for use as `(config.lib.nixGL.wrap
        <package>)`. Intended to start programs on the main GPU.

        Wrapper functions can be found under `config.lib.nixGL.wrappers`. They
        can be used directly, however, setting this option provides a convenient
        shorthand.

        The following wrappers are available:
        ${wrapperListMarkdown}
      '';
    };

    offloadWrapper = lib.mkOption {
      type = lib.types.enum (builtins.attrNames config.lib.nixGL.wrappers);
      default = "mesaPrime";
      description = ''
        The package wrapper function available for use as
        `(config.lib.nixGL.wrapOffload <package>)`. Intended to start programs
        on the secondary GPU.

        Wrapper functions can be found under `config.lib.nixGL.wrappers`. They
        can be used directly, however, setting this option provides a convenient
        shorthand.

        The following wrappers are available:
        ${wrapperListMarkdown}
      '';
    };

    prime.card = lib.mkOption {
      type = lib.types.str;
      default = "1";
      example = "pci-0000_06_00_0";
      description = ''
        Selects the non-default graphics card used for PRIME render offloading.
        The value can be:

        - a number, selecting the n-th non-default GPU;
        - a PCI bus id in the form `pci-XXX_YY_ZZ_U`;
        - a PCI id in the form `vendor_id:device_id`

        For more information, consult the Mesa documentation on the `DRI_PRIME`
        environment variable.
      '';
    };

    prime.nvidiaProvider = lib.mkOption {
      type = with lib.types; nullOr str;
      default = null;
      example = "NVIDIA-G0";
      description = ''
        If this option is set, it overrides the offload provider for Nvidia
        PRIME offloading. Consult the proprietary Nvidia driver documentation
        on the `__NV_PRIME_RENDER_OFFLOAD_PROVIDER` environment variable.
      '';
    };

    prime.installScript = lib.mkOption {
      type = with lib.types; nullOr (enum [ "mesa" "nvidia" ]);
      default = null;
      example = "mesa";
      description = ''
        If this option is set, the wrapper script `prime-offload` is installed
        into the environment. It allows starting programs on the secondary GPU
        selected by the `nixGL.prime.card` option. This makes sense when the
        program is not already using one of nixGL PRIME wrappers, or for
        programs not installed from Nixpkgs.

        This option can be set to either "mesa" or "nvidia", making the script
        use one or the other graphics library.
      '';
    };

    installScripts = lib.mkOption {
      type = with lib.types;
        nullOr (listOf (enum (builtins.attrNames config.lib.nixGL.wrappers)));
      default = null;
      example = [ "mesa" "mesaPrime" ];
      description = ''
        For each wrapper `wrp` named in the provided list, a wrapper script
        named `nixGLWrp` is installed into the environment. These scripts are
        useful for running programs not installed via Home Manager.

        The following wrappers are available:
        ${wrapperListMarkdown}
      '';
    };

    vulkan.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to enable Vulkan in nixGL wrappers.

        This is disabled by default bacause Vulkan brings in several libraries
        that can cause symbol version conflicts in wrapped programs. Your
        mileage may vary.
      '';
    };
  };

  config = let
    findWrapperPackage = packageAttr:
      # NixGL has wrapper packages in different places depending on how you
      # access it. We want HM configuration to be the same, regardless of how
      # NixGL is imported.
      #
      # First, let's see if we have a flake.
      if builtins.hasAttr pkgs.system cfg.packages then
        cfg.packages.${pkgs.system}.${packageAttr}
      else
      # Next, let's see if we have a channel.
      if builtins.hasAttr packageAttr cfg.packages then
        cfg.packages.${packageAttr}
      else
      # Lastly, with channels, some wrappers are grouped under "auto".
      if builtins.hasAttr "auto" cfg.packages then
        cfg.packages.auto.${packageAttr}
      else
        throw "Incompatible NixGL package layout";

    getWrapperExe = vendor:
      let
        glPackage = findWrapperPackage "nixGL${vendor}";
        glExe = lib.getExe glPackage;
        vulkanPackage = findWrapperPackage "nixVulkan${vendor}";
        vulkanExe = if cfg.vulkan.enable then lib.getExe vulkanPackage else "";
      in "${glExe} ${vulkanExe}";

    mesaOffloadEnv = { "DRI_PRIME" = "${cfg.prime.card}"; };

    nvOffloadEnv = {
      "DRI_PRIME" = "${cfg.prime.card}";
      "__NV_PRIME_RENDER_OFFLOAD" = "1";
      "__GLX_VENDOR_LIBRARY_NAME" = "nvidia";
      "__VK_LAYER_NV_optimus" = "NVIDIA_only";
    } // (let provider = cfg.prime.nvidiaProvider;
    in if !isNull provider then {
      "__NV_PRIME_RENDER_OFFLOAD_PROVIDER" = "${provider}";
    } else
      { });

    makePackageWrapper = vendor: environment: pkg:
      if builtins.isNull cfg.packages then
        pkg
      else
      # Wrap the package's binaries with nixGL, while preserving the rest of
      # the outputs and derivation attributes.
        (pkg.overrideAttrs (old: {
          name = "nixGL-${pkg.name}";

          # Make sure this is false for the wrapper derivation, so nix doesn't expect
          # a new debug output to be produced. We won't be producing any debug info
          # for the original package.
          separateDebugInfo = false;
          nativeBuildInputs = old.nativeBuildInputs or [ ]
            ++ [ pkgs.makeWrapper ];
          buildCommand = let
            # We need an intermediate wrapper package because makeWrapper
            # requires a single executable as the wrapper.
            combinedWrapperPkg =
              pkgs.writeShellScriptBin "nixGLCombinedWrapper-${vendor}" ''
                exec ${getWrapperExe vendor} "$@"
              '';
          in ''
            set -eo pipefail

            ${ # Heavily inspired by https://stackoverflow.com/a/68523368/6259505
            lib.concatStringsSep "\n" (map (outputName: ''
              echo "Copying output ${outputName}"
              set -x
              cp -rs --no-preserve=mode "${
                pkg.${outputName}
              }" "''$${outputName}"
              set +x
            '') (old.outputs or [ "out" ]))}

            rm -rf $out/bin/*
            shopt -s nullglob # Prevent loop from running if no files
            for file in ${pkg.out}/bin/*; do
              local prog="$(basename "$file")"
              makeWrapper \
                "${lib.getExe combinedWrapperPkg}" \
                "$out/bin/$prog" \
                --argv0 "$prog" \
                --add-flags "$file" \
                ${
                  lib.concatStringsSep " " (lib.attrsets.mapAttrsToList
                    (var: val: "--set '${var}' '${val}'") environment)
                }
            done

            # If .desktop files refer to the old package, replace the references
            for dsk in "$out/share/applications"/*.desktop ; do
              if ! grep -q "${pkg.out}" "$dsk"; then
                continue
              fi
              src="$(readlink "$dsk")"
              rm "$dsk"
              sed "s|${pkg.out}|$out|g" "$src" > "$dsk"
            done

            shopt -u nullglob # Revert nullglob back to its normal default state
          '';
        })) // {
          # When the nixGL-wrapped package is given to a HM module, the module
          # might want to override the package arguments, but our wrapper
          # wouldn't know what to do with them. So, we rewrite the override
          # function to instead forward the arguments to the package's own
          # override function.
          override = args:
            makePackageWrapper vendor environment (pkg.override args);
        };

    wrappers = {
      mesa = makePackageWrapper "Intel" { };
      mesaPrime = makePackageWrapper "Intel" mesaOffloadEnv;
      nvidia = makePackageWrapper "Nvidia" { };
      nvidiaPrime = makePackageWrapper "Nvidia" nvOffloadEnv;
    };
  in {
    lib.nixGL.wrap = wrappers.${cfg.defaultWrapper};
    lib.nixGL.wrapOffload = wrappers.${cfg.offloadWrapper};
    lib.nixGL.wrappers = wrappers;

    home.packages = let
      wantsPrimeWrapper = (!isNull cfg.prime.installScript);
      wantsWrapper = wrapper:
        (!isNull cfg.packages) && (!isNull cfg.installScripts)
        && (builtins.elem wrapper cfg.installScripts);
      envVarsAsScript = environment:
        lib.concatStringsSep "\n"
        (lib.attrsets.mapAttrsToList (var: val: "export ${var}=${val}")
          environment);
    in [
      (lib.mkIf wantsPrimeWrapper (pkgs.writeShellScriptBin "prime-offload" ''
        ${if cfg.prime.installScript == "mesa" then
          (envVarsAsScript mesaOffloadEnv)
        else
          (envVarsAsScript nvOffloadEnv)}
        exec "$@"
      ''))

      (lib.mkIf (wantsWrapper "mesa") (pkgs.writeShellScriptBin "nixGLMesa" ''
        exec ${getWrapperExe "Intel"} "$@"
      ''))

      (lib.mkIf (wantsWrapper "mesaPrime")
        (pkgs.writeShellScriptBin "nixGLMesaPrime" ''
          ${envVarsAsScript mesaOffloadEnv}
          exec ${getWrapperExe "Intel"} "$@"
        ''))

      (lib.mkIf (wantsWrapper "nvidia")
        (pkgs.writeShellScriptBin "nixGLNvidia" ''
          exec ${getWrapperExe "Nvidia"} "$@"
        ''))

      (lib.mkIf (wantsWrapper "nvidia")
        (pkgs.writeShellScriptBin "nixGLNvidiaPrime" ''
          ${envVarsAsScript nvOffloadEnv}
          exec ${getWrapperExe "Nvidia"} "$@"
        ''))
    ];
  };
}
