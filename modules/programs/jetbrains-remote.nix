{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.jetbrains-remote;

in {
  meta.maintainers = with lib.maintainers; [ genericnerdyusername ];

  options.programs.jetbrains-remote = {
    enable = mkEnableOption "JetBrains remote development system";

    ides = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression ''
        with pkgs.jetbrains; [ clion pycharm-professional ];
      '';
      description = ''
        IDEs accessible to the JetBrains remote development system.
      '';
    };
  };

  config = mkIf (cfg.enable && cfg.ides != [ ]) {
    home.activation.jetBrainsRemote = let
      mkLine = ide:
        # Errors out if the symlink already exists
        "${ide}/bin/${ide.meta.mainProgram}-remote-dev-server registerBackendLocationForGateway || true";
      lines = map mkLine cfg.ides;
      linesStr = ''
        rm $HOME/.cache/JetBrains/RemoteDev/userProvidedDist/_nix_store*
      '' + concatStringsSep "\n" lines;
    in hm.dag.entryAfter [ "writeBoundary" ] linesStr;
  };
}
