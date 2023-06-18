{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.senpai;
  imports = [
    (mkRenamedOptionModule [ "programs" "senpai" "addr" ] [
      "programs"
      "senpai"
      "address"
    ])
    (mkRenamedOptionModule [ "programs" "senpai" "nick" ] [
      "programs"
      "senpai"
      "nickname"
    ])
  ];
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
        options = {
          address = mkOption {
            type = types.str;
            description = ''
              The address (_host[:port]_) of the IRC server. senpai uses TLS
              connections by default unless you specify tls option to be false.
              TLS connections default to port 6697, plain-text use port 6667.

              ircs:// & irc:// & irc+insecure:// URLs are supported, in which
              case only the hostname and port parts will be used. If the scheme
              is ircs/irc+insecure, tls will be overriden and set to true/false
              accordingly.
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
          # TODO: remove me for the next release
          no-tls = mkOption {
            type = types.nullOr types.bool;
            default = null;
            description = ''
              Specifying 'senpai.no-tls' is deprecated,
              set 'senpai.extraConfig = { tls = false; }' instead.
            '';
          };
          password-cmd = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = ''
              Alternatively to providing your SASL authentication password
              directly in plaintext, you can specify a command to be run to
              fetch the password at runtime. This is useful if you store your
              passwords in a separate (probably encrypted) file using `gpg` or
              a command line password manager such as _pass_ or _gopass_. If a
              password-cmd is provided, the value of password will be ignored
              and the first line of the output of *password-cmd* will be used
              for login.
            '';
          };
        };
      };
    };
    extraConfig = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Options that should be appended to the senpai configuration file.
      '';
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
      <citerefentry><refentrytitle>senpai</refentrytitle>
      <manvolnum>5</manvolnum></citerefentry>.
    '';
  };

  config = mkIf cfg.enable {
    assertions = with cfg.config; [
      {
        assertion = !isNull password-cmd -> isNull password;
        message = "senpai: password-command overrides password!";
      }
      {
        # TODO: remove me for the next release
        assertion = isNull no-tls;
        message = ''
          Specifying 'senpai.no-tls' is deprecated,
          set 'senpai.extraConfig = { tls = false; }' instead.
        '';
      }
    ];
    home.packages = [ cfg.package ];
    xdg.configFile."senpai/senpai.scfg".text =
      lib.hm.generators.toSCFG (cfg.config // cfg.extraConfig);
  };

  meta.maintainers = [ maintainers.jleightcap ];
}
