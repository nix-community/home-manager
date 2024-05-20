{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.senpai;
in {
  options.programs.senpai = {
    enable = mkEnableOption "senpai";
    package = mkOption {
      type = types.package;
      default = pkgs.senpai;
      defaultText = literalExpression "pkgs.senpai";
      description = "The `senpai` package to use.";
    };
    config = mkOption {
      type = types.submodule {
        freeformType = types.attrsOf types.anything;
        options = {
          address = mkOption {
            type = types.str;
            description = ''
              The address (`host[:port]`) of the IRC server. senpai uses TLS
              connections by default unless you specify tls option to be false.
              TLS connections default to port 6697, plain-text use port 6667.

              UR`ircs://`, `irc://`, and `irc+insecure://` URLs are supported,
              in which case only the hostname and port parts will be used. If
              the scheme is `ircs/irc+insecure`, tls will be overriden and set
              to true/false accordingly.
            '';
          };

          nickname = mkOption {
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

          password-cmd = mkOption {
            type = types.nullOr (types.listOf types.str);
            default = null;
            example = [ "gopass" "show" "irc/guest" ];
            description = ''
              Alternatively to providing your SASL authentication password
              directly in plaintext, you can specify a command to be run to
              fetch the password at runtime. This is useful if you store your
              passwords in a separate (probably encrypted) file using `gpg` or a
              command line password manager such as `pass` or `gopass`. If a
              password-cmd is provided, the value of password will be ignored
              and the first line of the output of `password-cmd` will be used
              for login.
            '';
          };
        };
      };
      example = literalExpression ''
        {
          address = "libera.chat:6697";
          nickname = "nicholas";
          password = "verysecurepassword";
        }
      '';
      description = ''
        Configuration for senpai. For a complete list of options, see
        {manpage}`senpai(5)`.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = with cfg.config; [
      {
        assertion = !isNull password-cmd -> isNull password;
        message = "senpai: password-cmd overrides password!";
      }
      {
        assertion = !cfg.config ? addr;
        message = "senpai: addr is deprecated, use address instead";
      }
      {
        assertion = !cfg.config ? nick;
        message = "senpai: nick is deprecated, use nickname instead";
      }
      {
        assertion = !cfg.config ? no-tls;
        message = "senpai: no-tls is deprecated, use tls instead";
      }
    ];
    home.packages = [ cfg.package ];
    xdg.configFile."senpai/senpai.scfg".text =
      lib.hm.generators.toSCFG { } cfg.config;
  };

  meta.maintainers = [ hm.maintainers.malvo ];
}
