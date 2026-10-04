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
  defaultProfile = "home-manager";
in
{
  meta.maintainers = [
    lib.maintainers.da157
    lib.hm.maintainers.lukeaurio
  ];

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
        Written to {file}`$XDG_DATA_HOME/org.gnome.Ptyxis/palettes/NAME.palette`.
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

    defaultPalette = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myPalette";
      description = ''
        Palette to use for the Home Manager-managed default Ptyxis profile.

        When set, Home Manager creates a profile named `${defaultProfile}` and
        makes it Ptyxis's default profile. The palette can be one declared in
        {option}`programs.ptyxis.palettes` or a built-in Ptyxis palette. 
        See <https://gitlab.gnome.org/chergert/ptyxis/-/tree/main/data/palettes> for more information.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.ptyxis" pkgs lib.platforms.linux)
      {
        assertion = cfg.defaultPalette == null || cfg.defaultPalette != "";
        message = "programs.ptyxis.defaultPalette must not be an empty string.";
      }
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    xdg.dataFile = lib.mapAttrs' (
      name: value:
      lib.nameValuePair "org.gnome.Ptyxis/palettes/${name}.palette" {
        source =
          if lib.isString value then
            pkgs.writeText "ptyxis-theme-${name}" value
          else if builtins.isPath value || lib.isStorePath value then
            value
          else
            iniFormat.generate "ptyxis-theme-${name}" value;
      }
    ) cfg.palettes;

    dconf.settings = lib.optionalAttrs (cfg.defaultPalette != null) {
      "org/gnome/Ptyxis" = {
        default-profile-uuid = defaultProfile;
        profile-uuids = [ defaultProfile ];
      };
      "org/gnome/Ptyxis/Profiles/${defaultProfile}".palette = cfg.defaultPalette;
    };
  };
}
