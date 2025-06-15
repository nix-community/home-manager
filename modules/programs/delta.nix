{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    mkRenamedOptionModule
    optionalAttrs
    types
    ;

  cfg = config.programs.delta;
in
{
  meta.maintainers = with lib.maintainers; [
    khaneliman
    rycee
  ];

  imports = [
    (mkRenamedOptionModule
      [ "programs" "git" "delta" "enable" ]
      [ "programs" "delta" "enableGitIntegration" ]
    )
    (mkRenamedOptionModule [ "programs" "git" "delta" "package" ] [ "programs" "delta" "package" ])
    (mkRenamedOptionModule [ "programs" "git" "delta" "options" ] [ "programs" "delta" "settings" ])
  ];

  options.programs.delta = {
    enable = mkEnableOption "" // {
      default = cfg.enableGitIntegration;
      description = ''
        Whether to enable the {command}`delta` syntax highlighter.
        See <https://github.com/dandavison/delta>.
      '';
    };

    enableGitIntegration = mkEnableOption "" // {
      description = ''
        Whether to enable Git integration for the {command}`delta` syntax highlighter.
        See <https://github.com/dandavison/delta>.
      '';
    };

    package = mkPackageOption pkgs "delta" { };

    settings = mkOption {
      type =
        with types;
        let
          primitiveType = either str (either bool int);
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
  };

  config =
    let
      deltaConfig = pkgs.writeText "delta-config" (lib.generators.toGitINI { delta = cfg.settings; });
      finalPackage =
        if cfg.settings == { } then
          cfg.package
        else
          (pkgs.writeShellApplication {
            name = "delta";
            runtimeInputs = [ cfg.package ];
            text = ''
              exec ${getExe cfg.package} --config=${deltaConfig} "$@"
            '';
          });
      deltaExe = getExe finalPackage;
    in
    mkIf cfg.enable {
      home.packages = [ finalPackage ];

      programs.git = mkIf cfg.enableGitIntegration {
        iniContent = {
          core.pager = deltaExe;
          interactive.diffFilter = "${deltaExe} --color-only";
        };
      };
    };
}
