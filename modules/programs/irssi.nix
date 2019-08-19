{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.irssi;

  boolStr = b: if b then "yes" else "no";
  quoteStr = s: escape ["\""] s;

  assignFormat = set:
    concatStringsSep "\n"
      (mapAttrsToList (k: v: "  ${k} = \"${quoteStr v}\";") set);

  chatnetString =
    concatStringsSep "\n"
      (flip mapAttrsToList cfg.networks
      (k: v: ''
        ${k} = {
          type = "${v.type}";
          nick = "${quoteStr v.nick}";
          autosendcmd = "${concatMapStringsSep ";" quoteStr v.autoCommands}";
        };
      ''));

  serversString =
    concatStringsSep ",\n"
      (flip mapAttrsToList cfg.networks
      (k: v: ''
        {
          chatnet = "${k}";
          address = "${v.server.address}";
          port = "${toString v.server.port}";
          use_ssl = "${boolStr v.server.ssl.enable}";
          ssl_verify = "${boolStr v.server.ssl.verify}";
          autoconnect = "${boolStr v.server.autoConnect}";
        }
      ''));

  channelString =
    concatStringsSep ",\n"
      (flip mapAttrsToList cfg.networks
      (k: v:
        concatStringsSep ",\n"
          (flip mapAttrsToList v.channels
          (c: cv: ''
            {
              chatnet = "${k}";
              name = "${c}";
              autojoin = "${boolStr cv.autoJoin}";
            }
          ''))));

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

  networkType = types.submodule ({ name, ...}: {
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
        default = [];
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
        default = {};
      };
    };
  });

in

{

  options = {
    programs.irssi = {
      enable = mkEnableOption "the Irssi chat client";

      extraConfig = mkOption {
        default = "";
        description = "These lines are appended to the Irssi configuration.";
        type = types.str;
      };

      aliases = mkOption {
        default = {};
        example = { J = "join"; BYE = "quit";};
        description = "An attribute set that maps aliases to commands.";
        type = types.attrsOf types.str;
      };

      networks = mkOption {
        default = {};
        example = literalExample ''
          {
            freenode = {
              nick = "hmuser";
              server = {
                address = "chat.freenode.net";
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
