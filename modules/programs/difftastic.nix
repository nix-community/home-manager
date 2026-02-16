{
  config,
  options,
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
    (lib.mkRenamedOptionModule
      [ "programs" "git" "difftastic" "enable" ]
      [ "programs" "difftastic" "enable" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "difftastic" "package" ]
      [ "programs" "difftastic" "package" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "difftastic" "enableAsDifftool" ]
      [ "programs" "difftastic" "git" "diffToolMode" ]
    )
    (lib.mkRenamedOptionModule
      [ "programs" "git" "difftastic" "options" ]
      [ "programs" "difftastic" "options" ]
    )
  ]
  ++ (
    let
      mkRenamed =
        opt:
        lib.mkRenamedOptionModule
          [ "programs" "git" "difftastic" opt ]
          [ "programs" "git" "difftastic" "options" opt ];
    in
    map mkRenamed [
      "background"
      "color"
      "context"
      "display"
    ]
  )
  ++ [
    (lib.mkRemovedOptionModule [ "programs" "git" "difftastic" "extraArgs" ] ''
      'programs.git.difftastic.extraArgs' has been replaced by 'programs.git.difftastic.options'
    '')
  ];

  options.programs.difftastic = {
    enable = mkEnableOption "difftastic, a structural diff tool";

    package = mkPackageOption pkgs "difftastic" { };

    options = mkOption {
      type =
        with types;
        attrsOf (oneOf [
          str
          int
          bool
        ]);
      default = { };
      example = {
        color = "dark";
        sort-path = true;
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

          When enabled, difftastic will be configured as git's external diff tool or difftool
          depending on the value of {option}`programs.difftastic.git.diffToolMode`.
        '';
      };

      diffToolMode = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to additionally configure difftastic as a git difftool.

          When `false`, only `diff.external` is set (used for `git diff`).
          When `true`, both `diff.external` and difftool config are set (supporting both `git diff` and `git difftool`).
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

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "difftastic" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    mkMerge [
      (mkIf cfg.enable {
        home.packages = [ cfg.package ];

        # Auto-enable git integration if programs.git.difftastic.enable was set to true
        programs.difftastic.git.enable = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional (cfg.git.enable && options.programs.difftastic.git.enable.highestPrio == 1490)
            "`programs.difftastic.git.enable` automatic enablement is deprecated. Please explicitly set `programs.difftastic.git.enable = true`.";
      })

      (mkIf (cfg.enable && cfg.git.enable) {
        programs.git = {
          enable = lib.mkDefault true;
          iniContent =
            let
              difftCommand = "${lib.getExe cfg.package} ${lib.cli.toCommandLineShellGNU { } cfg.options}";
            in
            mkMerge [
              {
                diff.external = difftCommand;
              }
              (mkIf cfg.git.diffToolMode {
                diff.tool = lib.mkDefault "difftastic";
                difftool.difftastic.cmd = "${difftCommand} $LOCAL $REMOTE";
              })
            ];
        };
      })

      (mkIf (cfg.enable && cfg.jujutsu.enable) {
        programs.jujutsu.settings.ui.diff-formatter = [
          (lib.getExe cfg.package)
        ]
        ++ (lib.cli.toCommandLineGNU { } cfg.options)
        ++ [
          "--color=always"
          "--sort-paths"
          "$left"
          "$right"
        ];
      })
    ];
}
