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
    mkNushellIntegrationOption
    ;

  cfg = config.programs.vivid;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [
    lib.maintainers.arunoruto
  ];

  options.programs.vivid = {
    enable = mkEnableOption "vivid";
    package = mkPackageOption pkgs "vivid" { nullable = true; };

    enableBashIntegration = mkBashIntegrationOption { inherit config; };
    enableZshIntegration = mkZshIntegrationOption { inherit config; };
    enableFishIntegration = mkFishIntegrationOption { inherit config; };
    enableNushellIntegration = mkNushellIntegrationOption { inherit config; };

    colorMode = mkOption {
      type =
        with types;
        nullOr (
          either str (enum [
            "8-bit"
            "24-bit"
          ])
        );
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
        Active theme for vivid. With a managed package, colors are generated
        at build time; changes to runtime configuration or VIVID_THEME do not
        affect shell initialization. When null, generation runs at shell
        startup using VIVID_THEME instead.
      '';
    };

    themes = mkOption {
      type = with types; attrsOf (either path yamlFormat.type);
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

          my-custom-theme = {
            colors = {
              blue = "0000ff";
            };
            core = {
              directory = {
                foreground = "blue";
                font-style = "bold";
              };
            };
          };
        }
      '';
      description = ''
        An attribute set of vivid themes.
        Each value can either be a path to a theme file or an attribute set
        defining the theme directly (which will be converted from Nix to YAML).
      '';
    };

  };

  config =
    let
      generateAtBuildTime = cfg.package != null && cfg.activeTheme != null;
      vividCommand =
        theme:
        lib.escapeShellArgs (
          [ (if cfg.package != null then lib.getExe cfg.package else "vivid") ]
          ++ lib.optionals (cfg.colorMode != null) [
            "-m"
            cfg.colorMode
          ]
          ++ [ "generate" ]
          ++ lib.optional (theme != null) theme
        );
      colors =
        pkgs.runCommandLocal "vivid-ls-colors"
          (lib.optionalAttrs (cfg.filetypes != { }) {
            VIVID_DATABASE = config.xdg.configFile."vivid/filetypes.yml".source;
          })
          ''
            ${
              vividCommand (
                if builtins.hasAttr cfg.activeTheme cfg.themes then
                  "${config.xdg.configFile."vivid/themes/${cfg.activeTheme}.yml".source}"
                else
                  cfg.activeTheme
              )
            } > "$out"
          '';

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
        name: value:
        lib.nameValuePair "vivid/themes/${name}.yml" {
          source = if lib.isAttrs value then pkgs.writeText "${name}.json" (builtins.toJSON value) else value;
        }
      ) cfg.themes);

      programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
        export LS_COLORS="$(${if generateAtBuildTime then "<${colors}" else vividCommand cfg.activeTheme})"
      '';

      programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
        export LS_COLORS="$(${if generateAtBuildTime then "<${colors}" else vividCommand cfg.activeTheme})"
      '';

      programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
        set -gx LS_COLORS "$(${
          if generateAtBuildTime then "string collect < ${colors}" else vividCommand cfg.activeTheme
        })"
      '';

      programs.nushell.extraEnv = mkIf cfg.enableNushellIntegration ''
        $env.LS_COLORS = (${
          if generateAtBuildTime then
            ''open --raw ${colors} | str trim --right --char "\n"''
          else
            vividCommand cfg.activeTheme
        })
      '';
    };
}
