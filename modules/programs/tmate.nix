{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkOption
    optional
    types
    ;

  cfg = config.programs.tmate;
in
{
  meta.maintainers = [ lib.maintainers.jlesquembre ];

  options = {
    programs.tmate = {
      enable = lib.mkEnableOption "tmate";

      package = lib.mkPackageOption pkgs "tmate" { };

      host = mkOption {
        type = with types; nullOr str;
        default = null;
        example = literalExpression "tmate.io";
        description = "Tmate server address.";
      };

      port = mkOption {
        type = with types; nullOr port;
        default = null;
        example = 2222;
        description = "Tmate server port.";
      };

      dsaFingerprint = mkOption {
        type = with types; nullOr str;
        default = null;
        example = literalExpression "SHA256:1111111111111111111111111111111111111111111";
        description = "Tmate server EdDSA key fingerprint.";
      };

      rsaFingerprint = mkOption {
        type = with types; nullOr str;
        default = null;
        example = literalExpression "SHA256:1111111111111111111111111111111111111111111";
        description = "Tmate server RSA key fingerprint.";
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Additional content written at the end of
          {file}`~/.tmate.conf`.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".tmate.conf" =
      let
        conf =
          optional (cfg.host != null) ''set -g tmate-server-host "${cfg.host}"''
          ++ optional (cfg.port != null) "set -g tmate-server-port ${builtins.toString cfg.port}"
          ++ optional (
            cfg.dsaFingerprint != null
          ) ''set -g tmate-server-ed25519-fingerprint "${cfg.dsaFingerprint}"''
          ++ optional (
            cfg.rsaFingerprint != null
          ) ''set -g tmate-server-rsa-fingerprint "${cfg.rsaFingerprint}"''
          ++ optional (cfg.extraConfig != "") cfg.extraConfig;
      in
      lib.mkIf (conf != [ ]) { text = lib.concatLines conf; };
  };
}
