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
      The [nixGL](https://github.com/nix-community/nixGL) command that `lib.nixGL.wrap` should prefix
      package binaries with. nixGL provides your system's version of libGL to applications, enabling
      them to access the GPU on non-NixOS systems.

      Wrap individual packages which require GPU access with the function like so: `(config.lib.nixGL.wrap <package>)`.
      The returned package can be used just like the original one, but will have access to libGL. For example:

      ```nix
      # If you're using a Home Manager module to configure the package,
      # pass it into the module's package argument:
      programs.kitty = {
        enable = true;
        package = (config.lib.nixGL.wrap pkgs.kitty);
      };

      # Otherwise, pass it to any option where a package is expected:
      home.packages = [ (config.lib.nixGL.wrap pkgs.hello) ];
      ```

      If this option is empty (the default), then `lib.nixGL.wrap` is a no-op. This is useful for sharing your Home Manager
      configurations between NixOS and non-NixOS systems, since NixOS already provides libGL to applications without the
      need for nixGL.
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
          nativeBuildInputs = old.nativeBuildInputs or [ ]
            ++ [ pkgs.makeWrapper ];
          buildCommand = ''
            set -eo pipefail

            ${
            # Heavily inspired by https://stackoverflow.com/a/68523368/6259505
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
                "${cfg.prefix}" \
                "$out/bin/$prog" \
                --argv0 "$prog" \
                --add-flags "$file"
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
        }));
  };
}
