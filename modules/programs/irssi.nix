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
        description = "Name of the channel.";
      };

      autoJoin = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to join this channel on connect.";
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
        description = "Nickname in that network.";
      };

      type = mkOption {
        type = types.str;
        description = "Type of the network.";
        default = "IRC";
      };

      autoCommands = mkOption {
        type = types.listOf types.str;
        default = [ ];
        description = "List of commands to execute on connect.";
      };

      server = {
        address = mkOption {
          type = types.str;
          description = "Address of the chat server.";
        };

        port = mkOption {
          type = types.port;
          default = 6667;
          description = "Port of the chat server.";
        };

        ssl = {
          enable = mkOption {
            type = types.bool;
            default = true;
            description = "Whether SSL should be used.";
          };

          verify = mkOption {
            type = types.bool;
            default = true;
            description = "Whether the SSL certificate should be verified.";
          };

          certificateFile = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = ''
              Path to a file containing the certificate used for
              client authentication to the server.
            '';
          };
        };

        autoConnect = mkOption {
          type = types.bool;
          default = false;
          description = "Whether Irssi connects to the server on launch.";
        };
      };

      channels = mkOption {
        description = "Channels for the given network.";
        type = types.attrsOf channelType;
        default = { };
      };

      saslExternal = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable SASL external authentication. This requires setting a path in
          <xref linkend="opt-programs.irssi.networks._name_.server.ssl.certificateFile"/>.
        '';
      };
    };
  });

in {

  options = {
    programs.irssi = {
      enable = mkEnableOption "the Irssi chat client";

      extraConfig = mkOption {
        default = "";
        description = "These lines are appended to the Irssi configuration.";
        type = types.lines;
      };

      aliases = mkOption {
        default = { };
        example = {
          J = "join";
          BYE = "quit";
        };
        description = "An attribute set that maps aliases to commands.";
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
        description = "An attribute set of chat networks.";
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
