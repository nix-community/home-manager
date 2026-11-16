{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.difftastic;

  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    mkPackageOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkChangedOptionModule
      [ "programs" "difftastic" "git" "diffToolMode" ]
      [ "programs" "difftastic" "git" "mode" ]
      (config: if config.programs.difftastic.git.diffToolMode then "both" else "external")
    )
  ]
  ++ (lib.mapAttrsToList
    (name: message: lib.mkRemovedOptionModule [ "programs" "git" "difftastic" name ] message)
    {
      enable = "Use `programs.difftastic.enable` and `programs.difftastic.git.enable` instead.";
      package = "Use `programs.difftastic.package` instead.";
      options = "Use `programs.difftastic.options` instead.";
      background = "Use `programs.difftastic.options.background` instead.";
      color = "Use `programs.difftastic.options.color` instead.";
      context = "Use `programs.difftastic.options.context` instead.";
      display = "Use `programs.difftastic.options.display` instead.";
      enableAsDifftool = "Set `programs.difftastic.git.mode = \"both\"` instead.";
      extraArgs = "Use `programs.difftastic.options` instead.";
    }
  );

  options.programs.difftastic = {
    enable = mkEnableOption "difftastic, a structural diff tool";

    package = mkPackageOption pkgs "difftastic" { };

    options = mkOption {
      type =
        with types;
        let
          atom = oneOf [
            str
            int
            bool
          ];
        in
        attrsOf (either atom (listOf atom));
      default = { };
      example = {
        color = "always";
        sort-paths = true;
        tab-width = 8;
      };
      description = "Configuration options for {command}`difftastic`. See {command}`difft --help`";
    };

    git = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable git integration for difftastic.

          When enabled, difftastic will be configured as git's external diff
          command, as a git difftool, or both, depending on the value of
          {option}`programs.difftastic.git.mode`.
        '';
      };

      mode = mkOption {
        type = types.enum [
          "external"
          "difftool"
          "both"
        ];
        default = "external";
        example = "difftool";
        description = ''
          How difftastic integrates with git.

          - `"external"`: set `diff.external` so {command}`git diff` uses
            difftastic by default.
          - `"difftool"`: only configure difftastic as a git difftool
            (`diff.tool` and `difftool.difftastic.cmd`), leaving
            {command}`git diff` untouched.
          - `"both"`: configure both `diff.external` and the difftool.
        '';
      };
    };

    jujutsu = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable jujutsu integration for difftastic.
        '';
      };
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ cfg.package ];
    })

    (mkIf (cfg.enable && cfg.git.enable) {
      programs.git = {
        enable = lib.mkDefault true;
        iniContent =
          let
            difftCommand = "${lib.getExe cfg.package} ${lib.cli.toCommandLineShellGNU { } cfg.options}";
          in
          mkMerge [
            (mkIf
              (lib.elem cfg.git.mode [
                "external"
                "both"
              ])
              {
                diff.external = difftCommand;
              }
            )
            (mkIf
              (lib.elem cfg.git.mode [
                "difftool"
                "both"
              ])
              {
                diff.tool = lib.mkDefault "difftastic";
                difftool.difftastic.cmd = "${difftCommand} $LOCAL $REMOTE";
              }
            )
          ];
      };
    })

    (mkIf (cfg.enable && cfg.jujutsu.enable) {
      programs.jujutsu.settings.ui.diff-formatter = [
        (lib.getExe cfg.package)
      ]
      ++ (lib.cli.toCommandLineGNU { } (
        cfg.options
        // {
          color = "always";
          sort-paths = true;
          width = "$width";
        }
      ))
      ++ [
        "$left"
        "$right"
      ];
    })
  ];
}
