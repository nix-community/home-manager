{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib) types mkIf;

  iniFormat = pkgs.formats.ini { };
  cfg = config.programs.ptyxis;
in
{
  meta.maintainers = [ lib.maintainers.awwpotato ];

  options.programs.ptyxis = {
    enable = lib.mkEnableOption "ptyxis";

    package = lib.mkPackageOption pkgs "ptyxis" { nullable = true; };

    palettes = lib.mkOption {
      type =
        with types;
        attrsOf (oneOf [
          iniFormat.type
          path
          str
        ]);
      default = { };
      description = ''
        Written to {file}`$XDG_CONFIG_HOME/org.gnome.Prompt/palettes/NAME.palette`.
        See <https://gitlab.gnome.org/chergert/ptyxis/-/tree/main/data/palettes>
        for more information.
      '';
      example = lib.literalExpression ''
        {
          myPalette = {
            Palette.Name = "My awesome theme";
            Light = {
              Foreground="#E2E2E3";
              Background="#2C2E34";
              Color0="#2C2E34";
              Color1="#FC5D7C";
              Color2="#9ED072";
              Color3="#E7C664";
              Color4="#F39660";
            };
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.ptyxis" pkgs lib.platforms.linux)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = lib.mapAttrs' (
      name: value:
      lib.nameValuePair "org.gnome.Prompt/palettes/${name}.palette" {
        source =
          if lib.isString value then
            pkgs.writeText "ptyxis-theme-${name}" value
          else if builtins.isPath value || lib.isStorePath value then
            value
          else
            iniFormat.generate "ptyxis-theme-${name}" value;
      }
    ) cfg.palettes;
  };
}
