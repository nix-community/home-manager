{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.alacritty;
  tomlFormat = pkgs.formats.toml { };
in
{
  options = {
    programs.alacritty = {
      enable = lib.mkEnableOption "Alacritty";

      package = lib.mkPackageOption pkgs "alacritty" { nullable = true; };

      themePackage = lib.mkPackageOption pkgs "alacritty-theme" { };

      theme = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "solarized_dark";
        description = ''
          A theme from the
          [alacritty-theme](https://github.com/alacritty/alacritty-theme)
          repository to import in the configuration.
          See <https://github.com/alacritty/alacritty-theme/tree/master/themes>
          for a list of available themes.
          If you would like to import your own theme, use
          {option}`programs.alacritty.settings.general.import` or
          {option}`programs.alacritty.settings.colors` directly.
        '';
      };

      settings = lib.mkOption {
        inherit (tomlFormat) type;
        default = { };
        example = {
          window.dimensions = {
            lines = 3;
            columns = 200;
          };
          keyboard.bindings = [
            {
              key = "K";
              mods = "Control";
              chars = "\\u000c";
            }
          ];
        };
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/alacritty/alacritty.yml` or
          {file}`$XDG_CONFIG_HOME/alacritty/alacritty.toml`
          (the latter being used for alacritty 0.13 and later).
          See <https://github.com/alacritty/alacritty/tree/master#configuration>
          for more info.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs.alacritty.settings =
      let
        # We want to check that the theme actually exists.
        # We need to do this at build time, to avoid IFD.
        alacrittyTheme = cfg.themePackage.overrideAttrs (prevAttrs: {
          name = "alacritty-theme-for-home-manager";
          postInstall =
            let
              inherit (config.programs.alacritty) theme;
            in
            lib.concatStringsSep "\n" [
              (prevAttrs.postInstall or "")
              (lib.optionalString (theme != null)
                # bash
                ''
                  if [ ! -f "$out/share/alacritty-theme/${theme}.toml" ]; then
                    echo "error: alacritty theme '${theme}' does not exist"
                    exit 1
                  fi
                ''
              )
            ];
        });

        theme = "${alacrittyTheme}/share/alacritty-theme/${cfg.theme}.toml";
      in
      lib.mkIf (cfg.theme != null) {
        general.import = lib.mkIf (lib.versionAtLeast cfg.package.version "0.14") [ theme ];
        import = lib.mkIf (lib.versionOlder cfg.package.version "0.14") [ theme ];
      };

    xdg.configFile."alacritty/alacritty.toml" = lib.mkIf (cfg.settings != { }) {
      source = (tomlFormat.generate "alacritty.toml" cfg.settings).overrideAttrs (
        _finalAttrs: prevAttrs: {
          buildCommand = lib.concatStringsSep "\n" [
            prevAttrs.buildCommand
            # Nix cannot spell TOML escape sequences like "\u001d" directly:
            # "\\u001d" is a literal backslash-u string, while fromJSON creates
            # a control character and fails for "\u0000". Normalize both TOML
            # generator outputs to the Alacritty escape form:
            #   chars = "\\u001d" -> chars = "\u001d"
            #   chars = '\u001d'  -> chars = "\u001d"
            ''
              sed \
                -E \
                -e "s/= \"\\\\\\\\u([0-9a-fA-F]{4})\"\$/= \"\\\\u\1\"/" \
                -e "s/= '\\\\u([0-9a-fA-F]{4})'\$/= \"\\\\u\1\"/" \
                "$out" > "$TMPDIR/alacritty.toml"
              cp "$TMPDIR/alacritty.toml" "$out"
            ''
          ];
        }
      );
    };
  };
}
