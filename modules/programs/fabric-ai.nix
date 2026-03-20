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
    ;

  inherit (lib.hm.shell)
    mkBashIntegrationOption
    mkZshIntegrationOption
    ;

  cfg = config.programs.fabric-ai;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.fabric-ai = {
    enable = mkEnableOption "Fabric AI";
    package = mkPackageOption pkgs "fabric-ai" { nullable = true; };
    enablePatternsAliases = mkEnableOption "aliases for all Fabric's patterns";
    enableYtAlias = mkEnableOption "Fabric's `yt` alias" // {
      default = true;
    };
    enableBashIntegration = mkBashIntegrationOption { inherit config; };
    enableZshIntegration = mkZshIntegrationOption { inherit config; };
  };

  config =
    let
      posixShellCode = ''
        ${lib.optionalString cfg.enablePatternsAliases ''
          for pattern_file in $HOME/.config/fabric/patterns/*; do
              pattern_name="$(basename "$pattern_file")"
              alias_name="''${FABRIC_ALIAS_PREFIX:-}''${pattern_name}"

              alias_command="alias $alias_name='fabric --pattern $pattern_name'"

              eval "$alias_command"
          done
        ''}

        ${lib.optionalString cfg.enableYtAlias ''
          yt() {
              if [ "$#" -eq 0 ] || [ "$#" -gt 2 ]; then
                  echo "Usage: yt [-t | --timestamps] youtube-link"
                  echo "Use the '-t' flag to get the transcript with timestamps."
                  return 1
              fi

              transcript_flag="--transcript"
              if [ "$1" = "-t" ] || [ "$1" = "--timestamps" ]; then
                  transcript_flag="--transcript-with-timestamps"
                  shift
              fi
              local video_link="$1"
              fabric -y "$video_link" $transcript_flag
          }
        ''}
      '';
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      programs.bash.initExtra = mkIf cfg.enableBashIntegration posixShellCode;
      programs.zsh.initContent = mkIf cfg.enableZshIntegration posixShellCode;
    };
}
