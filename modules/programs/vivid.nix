{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    types
    ;

  inherit (lib.hm.shell)
    mkBashIntegrationOption
    mkZshIntegrationOption
    mkFishIntegrationOption
    ;

  cfg = config.programs.vivid;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.vivid = {
    enable = mkEnableOption "vivid";
    package = mkPackageOption pkgs "vivid" { nullable = true; };

    enableBashIntegration = mkBashIntegrationOption { inherit config; };
    enableZshIntegration = mkZshIntegrationOption { inherit config; };
    enableFishIntegration = mkFishIntegrationOption { inherit config; };

    colorMode = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "8-bit";
      description = ''
        Color mode for vivid.
      '';
    };

    filetypes = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        text = {
          special = [
            "CHANGELOG.md"
            "CODE_OF_CONDUCT.md"
            "CONTRIBUTING.md"
          ];

          todo = [
            "TODO.md"
            "TODO.txt"
          ];

          licenses = [
            "LICENCE"
            "COPYRIGHT"
          ];
        };
      };
      description = ''
        Filetype database for vivid. You can find an example config at:
        <https://github.com/sharkdp/vivid/blob/master/config/filetypes.yml>.
      '';
    };

    activeTheme = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "molokai";
      description = ''
        Active theme for vivid.
      '';
    };

    themes = mkOption {
      type = with types; attrsOf path;
      default = { };
      example = lib.literalExpression ''
        {
          ayu = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/NearlyTRex/Vivid/refs/heads/master/themes/ayu.yml";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };

          mocha = builtins.fetchurl {
            url = "https://raw.githubusercontent.com/NearlyTRex/Vivid/refs/heads/master/themes/catppuccin-mocha.yml";
            hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          };
        }
      '';
      description = "Theme for vivid";
    };
  };

  config =
    let
      vividCommand = "vivid ${
        lib.optionalString (cfg.colorMode != null) "-m ${cfg.colorMode}"
      } generate ${lib.optionalString (cfg.activeTheme != null) cfg.activeTheme}";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];

      home.sessionVariables = mkIf (cfg.activeTheme != null) { VIVID_THEME = cfg.activeTheme; };

      xdg.configFile = {
        "vivid/filetypes.yml" = mkIf (cfg.filetypes != { }) {
          source = yamlFormat.generate "vivid-filetypes" cfg.filetypes;
        };
      }
      // (lib.mapAttrs' (
        name: path: lib.nameValuePair "vivid/themes/${name}.yml" { source = path; }
      ) cfg.themes);

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        export LS_COLORS="$(${vividCommand})"
      '';

      programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
        export LS_COLORS="$(${vividCommand})"
      '';

      programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        set -gx LS_COLORS "$(${vividCommand})"
      '';
    };
}
