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
      source =
        let
          # `pkgs.formats.toml` escapes backslashes and cannot emit raw
          # control characters (NUL cannot even appear in a Nix string), so a
          # `chars` escape like "\u001d" generates as literal "\\u001d",
          # which Alacritty rejects. Stash each escape behind a placeholder that
          # survives generation, then restore "\u" in the build command.
          unicodeEscapePrefix = "__home_manager_alacritty_unicode_escape_";

          normalizeAlacrittyEscapes =
            value:
            if builtins.isAttrs value then
              lib.mapAttrs (_: normalizeAlacrittyEscapes) value
            else if builtins.isList value then
              map normalizeAlacrittyEscapes value
            else if !builtins.isString value then
              value
            else
              # Normalize the "\^[" caret form to "\u001b", then replace every
              # "\uXXXX" with the placeholder.
              lib.concatMapStrings (
                chunk: if builtins.isList chunk then unicodeEscapePrefix + builtins.head chunk else chunk
              ) (builtins.split "\\\\u([0-9a-fA-F]{4})" (builtins.replaceStrings [ "\\^[" ] [ "\\u001b" ] value));
        in
        (tomlFormat.generate "alacritty.toml" (normalizeAlacrittyEscapes cfg.settings)).overrideAttrs
          (prevAttrs: {
            buildCommand = lib.concatStringsSep "\n" [
              prevAttrs.buildCommand
              ''substituteInPlace $out --replace-quiet '${unicodeEscapePrefix}' '\u' ''
            ];
          });
    };
  };
}
