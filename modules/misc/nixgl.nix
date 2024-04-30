{ config, lib, pkgs, ... }:

let cfg = config.nixGL;
in {
  meta.maintainers = [ lib.maintainers.smona ];

  options.nixGL.prefix = lib.mkOption {
    type = lib.types.str;
    default = "";
    example = lib.literalExpression
      ''"''${inputs.nixGL.packages.x86_64-linux.nixGLIntel}/bin/nixGLIntel"'';
    description = ''
      The nixGL command that `lib.nixGL.wrap` should wrap packages with.
      This can be used to provide libGL access to applications on non-NixOS systems.

      Some packages are wrapped by default (e.g. kitty, firefox), but you can wrap other packages
      as well, with `(config.lib.nixGL.wrap <package>)`. If this option is empty (the default),
      then `lib.nixGL.wrap` is a no-op.
    '';
  };

  config = {
    lib.nixGL.wrap = # Wrap a single package with the configured nixGL wrapper
      pkg:

      if cfg.prefix == "" then
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

          buildCommand = ''
            set -eo pipefail

            ${
            # Heavily inspired by https://stackoverflow.com/a/68523368/6259505
            pkgs.lib.concatStringsSep "\n" (map (outputName: ''
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
              echo "#!${pkgs.bash}/bin/bash" > "$out/bin/$(basename $file)"
              echo "exec -a \"\$0\" ${cfg.prefix} $file \"\$@\"" >> "$out/bin/$(basename $file)"
              chmod +x "$out/bin/$(basename $file)"
            done
            shopt -u nullglob # Revert nullglob back to its normal default state
          '';
        }));
  };
}
