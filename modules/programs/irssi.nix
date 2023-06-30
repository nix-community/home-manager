{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.irssi;

  quoteStr = s: escape [ ''"'' ] s;

  # Comma followed by newline.
  cnl = ''
    ,
  '';

  assignFormat = set:
    concatStringsSep "\n"
    (mapAttrsToList (k: v: "  ${k} = \"${quoteStr v}\";") set);

  chatnetString = concatStringsSep "\n" (flip mapAttrsToList cfg.networks
    (k: v: ''
      ${k} = {
        type = "${v.type}";
        nick = "${quoteStr v.nick}";
        autosendcmd = "${concatMapStringsSep ";" quoteStr v.autoCommands}";
        ${
          lib.optionalString (v.saslExternal) ''
            sasl_username = "${quoteStr v.nick}";
              sasl_mechanism = "EXTERNAL";''
        }
      };
    ''));

  serversString = concatStringsSep cnl (flip mapAttrsToList cfg.networks
    (k: v: ''
      {
        chatnet = "${k}";
        address = "${v.server.address}";
        port = "${toString v.server.port}";
        use_ssl = "${lib.hm.booleans.yesNo v.server.ssl.enable}";
        ssl_verify = "${lib.hm.booleans.yesNo v.server.ssl.verify}";
        autoconnect = "${lib.hm.booleans.yesNo v.server.autoConnect}";
        ${
          optionalString (v.server.ssl.certificateFile != null) ''
            ssl_cert = "${v.server.ssl.certificateFile}";
          ''
        }
      }
    ''));

  channelString = concatStringsSep cnl (concatLists
    (flip mapAttrsToList cfg.networks (k: v:
      (flip mapAttrsToList v.channels (c: cv: ''
        {
          chatnet = "${k}";
          name = "${c}";
          autojoin = "${lib.hm.booleans.yesNo cv.autoJoin}";
        }
      '')))));

  channelType = types.submodule {
    options = {
      name = mkOption {
        type = types.nullOr types.str;
        visible = false;
        default = null;
        description = lib.mdDoc "Name of the channel.";
      };

      autoJoin = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to join this channel on connect.";
      };
    };
  };

  networkType = types.submodule ({ name, ... }: {
    options = {
      name = mkOption {
        visible = false;
        default = name;
        type = types.str;
      };

      nick = mkOption {
        type = types.str;
        description = lib.mdDoc "Nickname in that network.";
      };

      type = mkOption {
        type = types.str;
        description = lib.mdDoc "Type of the network.";
        default = "IRC";
      };

      autoCommands = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = lib.mdDoc "List of commands to execute on connect.";
      };

      server = {
        address = mkOption {
          type = types.str;
          description = lib.mdDoc "Address of the chat server.";
        };

        port = mkOption {
          type = types.port;
          default = 6667;
          description = lib.mdDoc "Port of the chat server.";
        };

        ssl = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = lib.mdDoc "Whether SSL should be used.";
          };

          verify = mkOption {
            type = types.bool;
            default = true;
            description =
              lib.mdDoc "Whether the SSL certificate should be verified.";
          };

          certificateFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = lib.mdDoc ''
              Path to a file containing the certificate used for
              client authentication to the server.
            '';
          };
        };

        autoConnect = mkOption {
          type = types.bool;
          default = false;
          description =
            lib.mdDoc "Whether Irssi connects to the server on launch.";
        };
      };

      channels = mkOption {
        description = lib.mdDoc "Channels for the given network.";
        type = types.attrsOf channelType;
        default = { };
      };

      saslExternal = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Enable SASL external authentication. This requires setting a path in
          [](#opt-programs.irssi.networks._name_.server.ssl.certificateFile).
        '';
      };
    };
  });

in {

  options = {
    programs.irssi = {
      enable = mkEnableOption (lib.mdDoc "the Irssi chat client");

      extraConfig = mkOption {
        default = "";
        description =
          lib.mdDoc "These lines are appended to the Irssi configuration.";
        type = types.lines;
      };

      aliases = mkOption {
        default = { };
        example = {
          J = "join";
          BYE = "quit";
        };
        description =
          lib.mdDoc "An attribute set that maps aliases to commands.";
        type = types.attrsOf types.str;
      };

      networks = mkOption {
        default = { };
        example = literalExpression ''
          {
            liberachat = {
              nick = "hmuser";
              server = {
                address = "irc.libera.chat";
                port = 6697;
                autoConnect = true;
              };
              channels = {
                nixos.autoJoin = true;
              };
            };
          }
        '';
        description = lib.mdDoc "An attribute set of chat networks.";
        type = types.attrsOf networkType;
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.irssi ];

    home.file.".irssi/config".text = ''
      settings = {
        core = {
          settings_autosave = "no";
        };
      };

      aliases = {
      ${assignFormat cfg.aliases}
      };

      chatnets = {
      ${chatnetString}
      };

      servers = (
      ${serversString}
      );

      channels = (
      ${channelString}
      );

      ${cfg.extraConfig}
    '';
  };
}
