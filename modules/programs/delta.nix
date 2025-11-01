{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.delta;

  inherit (lib)
    mkOption
    types
    ;
in
{
  meta.maintainers = with lib.maintainers; [ khaneliman ];

  imports = [
    (lib.mkRenamedOptionModule [ "programs" "git" "delta" "enable" ] [ "programs" "delta" "enable" ])
    (lib.mkRenamedOptionModule [ "programs" "git" "delta" "package" ] [ "programs" "delta" "package" ])
    (lib.mkRenamedOptionModule [ "programs" "git" "delta" "options" ] [ "programs" "delta" "options" ])
  ];

  options.programs.delta = {
    enable = lib.mkEnableOption "delta, a syntax highlighter for git diffs";

    package = lib.mkPackageOption pkgs "delta" { };

    options = mkOption {
      type =
        with types;
        let
          primitiveType = oneOf [
            str
            bool
            int
          ];
          sectionType = attrsOf primitiveType;
        in
        attrsOf (either primitiveType sectionType);
      default = { };
      example = {
        features = "decorations";
        whitespace-error-style = "22 reverse";
        decorations = {
          commit-decoration-style = "bold yellow box ul";
          file-style = "bold yellow ul";
          file-decoration-style = "none";
        };
      };
      description = ''
        Options to configure delta.
      '';
    };

    enableGitIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git integration for delta.

        When enabled, delta will be configured as git's pager and diff filter.
      '';
    };

    enableJujutsuIntegration = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable jujutsu integration for delta.

        When enabled, delta will be configured as jujutsus's pager, diff filter, and merge tool.
      '';
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      visible = false;
      default =
        let
          configFile = pkgs.writeText "delta-config" (lib.generators.toGitINI { delta = cfg.options; });
          wrappedDelta = pkgs.symlinkJoin {
            name = "delta-wrapped";
            paths = [ cfg.package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/delta \
                --add-flags "--config ${configFile}"
            '';
            inherit (cfg.package) meta;
          };
          hasGitConfig = cfg.enableGitIntegration && config.programs.git.enable;
        in
        if !hasGitConfig && cfg.options != { } then wrappedDelta else cfg.package;
      description = ''
        The delta package with configuration wrapper applied.

        When git integration is disabled and options are configured,
        this is a wrapped version that passes --config to delta.
        Otherwise, it's the unwrapped package.
      '';
    };
  };

  config =
    let
      oldOption = lib.attrByPath [ "programs" "git" "delta" "enable" ] null options;
      oldOptionEnabled =
        oldOption != null && oldOption.isDefined && (builtins.length oldOption.files) > 0;
    in
    lib.mkMerge [
      (lib.mkIf cfg.enable {
        home.packages = [ cfg.finalPackage ];

        programs.delta.enableGitIntegration = lib.mkIf oldOptionEnabled (lib.mkOverride 1490 true);

        warnings =
          lib.optional
            (cfg.enableGitIntegration && options.programs.delta.enableGitIntegration.highestPrio == 1490)
            "`programs.delta.enableGitIntegration` automatic enablement is deprecated. Please explicitly set `programs.delta.enableGitIntegration = true`.";
      })

      (lib.mkIf (cfg.enable && cfg.enableGitIntegration) {
        programs.git.iniContent =
          let
            deltaCommand = lib.getExe cfg.package;
          in
          {
            core.pager = deltaCommand;
            interactive.diffFilter = "${deltaCommand} --color-only";
            delta = cfg.options;
          };
      })

      (lib.mkIf (cfg.enable && cfg.enableJujutsuIntegration) {
        assertions = [
          {
            assertion = config.programs.jujutsu.enable or false;
            message = "programs.delta.enableJujutsuIntegration requires programs.jujutsu.enable to be true";
          }
        ];

        programs.jujutsu.settings = {
          merge-tools.delta.diff-expected-exit-codes = lib.mkDefault [
            0
            1
          ];
          ui = {
            diff-formatter = lib.mkDefault ":git";
            pager = lib.mkDefault "${lib.getExe cfg.package}";
          };
        };
      })
    ];
}
