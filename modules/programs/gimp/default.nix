{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    mkPackageOption
    types
    ;
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  imports = [
    ./config.nix
    ./options/gimprc.nix
    ./options/content.nix
    ./options/paint.nix
    ./options/input.nix
    ./options/appearance.nix
  ];

  options.programs.gimp = {
    enable = mkEnableOption "GIMP image editor";

    package = mkPackageOption pkgs "gimp" { nullable = true; };

    configVersion = mkOption {
      type = types.str;
      default =
        if config.programs.gimp.package != null then
          lib.versions.majorMinor config.programs.gimp.package.version
        else
          throw ''
            programs.gimp.configVersion has no package to derive a default
            from because programs.gimp.package is null .
          '';
      defaultText = literalExpression "lib.versions.majorMinor config.programs.gimp.package.version";
      example = "3.2";
      description = ''
        Config directory version suffix used for
        {file}`$XDG_CONFIG_HOME/GIMP/<configVersion>/`.

        Automatically derived from the package version when
        {option}`programs.gimp.package` is set (e.g. `"3.0"` for GIMP 3.0.x,
        `"3.2"` for GIMP 3.2.x). Must be set explicitly when
        {option}`programs.gimp.package` is `null`.
      '';
    };
  };
}
