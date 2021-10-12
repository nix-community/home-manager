{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.senpai;
  cfgFmt = pkgs.formats.yaml { };
in {
  options.programs.senpai = {
    enable = mkEnableOption "senpai";
    package = mkOption {
      type = types.package;
      default = pkgs.senpai;
      defaultText = literalExpression "pkgs.senpai";
      description = "The <literal>senpai</literal> package to use.";
    };
    config = mkOption {
      type = types.submodule {
        freeformType = cfgFmt.type;
        options = {
          addr = mkOption {
            type = types.str;
            description = ''
              The address (host[:port]) of the IRC server. senpai uses TLS
              connections by default unless you specify no-tls option. TLS
              connections default to port 6697, plain-text use port 6667.
            '';
          };
          nick = mkOption {
            type = types.str;
            description = ''
              Your nickname, sent with a NICK IRC message. It mustn't contain
              spaces or colons (:).
            '';
          };
          password = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Your password, used for SASL authentication. Note that it will
              reside world-readable in the Nix store.
            '';
          };
          no-tls = mkOption {
            type = types.bool;
            default = false;
            description = "Disables TLS encryption.";
          };
        };
      };
      example = literalExpression ''
        {
          addr = "libera.chat:6697";
          nick = "nicholas";
          password = "verysecurepassword";
        }
      '';
      description = ''
        Configuration for senpai. For a complete list of options, see
        <citerefentry><refentrytitle>senpai</refentrytitle>
        <manvolnum>5</manvolnum></citerefentry>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."senpai/senpai.yaml".source =
      cfgFmt.generate "senpai.yaml" cfg.config;
  };

  meta.maintainers = [ hm.maintainers.malvo ];
}
