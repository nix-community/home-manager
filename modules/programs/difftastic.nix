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
    (lib.mkChangedOptionModule
      [ "programs" "git" "difftastic" "enableAsDifftool" ]
      [ "programs" "difftastic" "git" "mode" ]
      (config: if config.programs.git.difftastic.enableAsDifftool then "both" else "external")
    )
    (lib.mkChangedOptionModule
      [ "programs" "difftastic" "git" "diffToolMode" ]
      [ "programs" "difftastic" "git" "mode" ]
      (config: if config.programs.difftastic.git.diffToolMode then "both" else "external")
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
          }
        ))
        ++ [
          "$left"
          "$right"
        ];
      })
    ];
}
