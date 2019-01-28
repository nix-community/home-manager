{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.irssi;

  ifToYesNo = b: if b then "yes" else "no";
  quoteStr = s: escape ["\""] s;

  assignFormat =
    set:
      concatStringsSep "\n"
        (
        mapAttrsToList (k: v: "  ${k} = \"${quoteStr v}\";") set
        );

  chatnetString =
    concatStringsSep "\n"
      ( mapAttrsToList
        (k: v: ''
          ${k} = {
            type = "${v.type}";
            nick = "${quoteStr v.nick}";
            autosendcmd = "${concatMapStringsSep ";" quoteStr v.autoCommands}";
          };
        '')
        cfg.networks
      );

  serversString =
    concatStringsSep ",\n"
      ( mapAttrsToList
        (k: v: ''
        {
          chatnet = "${k}";
          address = "${v.server.address}";
          port = "${toString v.server.port}";
          use_ssl = "${ifToYesNo v.server.ssl.enable}";
          ssl_verify = "${ifToYesNo v.server.ssl.verify}";
          autoconnect = "${ifToYesNo v.server.autoConnect}";
        }'')
        cfg.networks
      );

  channelString =
    concatStringsSep ",\n"
      ( mapAttrsToList
        (k: v: concatStringsSep ",\n"
          ( mapAttrsToList
            (c: cv: ''
            {
              chatnet = "${k}";
              name = "${c}";
              autojoin = "${ifToYesNo cv.autoJoin}";
            }'')
            v.channels)
        )
        cfg.networks
      );

  serverType =
    types.submodule (
      {name, ...}: {
        options = {
          address = mkOption {
            type = types.str;
            description = "Address of the chat server.";
          };

          port = mkOption {
            type = types.int;
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
      }
    );

  channelType =
    types.submodule {
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

in

{

  options = {
    programs.irssi = {
      enable = mkEnableOption "the Irssi chat client";

      extraConfig = mkOption {
        default = "";
        description = "These lines are appended to the Irssi config.";
        type = types.str;
      };

      aliases = mkOption {
        default = {};
        example = { J = "join"; BYE = "quit";};
        description = "An attribute set that maps aliases to commands.";
        type = types.attrs;
      };

      networks = mkOption {
        default = {};
        description = "An attribute set of chat networks.";
        type = types.attrsOf (
          types.submodule (
            { name, ...}: {
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

                server = mkOption {
                  description = "Server settings for the given network.";
                  type = serverType;
                };

                channels = mkOption {
                  description = "Channels for the given network.";
                  type = types.attrsOf channelType;
                  default = {};
                };
              };
            }
          )
        );
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
