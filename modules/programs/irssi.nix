{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.irssi;

  ifToYesNo = b: if b then "yes" else "no";

  assignFormat =
    set:
      concatStringsSep "\n"
        (
          mapAttrsToList (k: v: "  ${k} = \"${v}\";") set
        );

  chatnetString =
    concatStringsSep "\n"
      ( mapAttrsToList
        (k: v: ''
          ${k} = {
            type = "${v.type}";
            nick = "${v.nick}";
            autosendcmd = "${concatStringsSep ";" v.autoCmd}";
          };
        '')
        cfg.chatnets
      );

  serversString =
    concatStringsSep ",\n"
      ( mapAttrsToList
        (k: v: ''
        {
          chatnet = "${k}";
          address = "${v.server.address}";
          port = "${toString v.server.port}";
          use_ssl = "${ifToYesNo v.server.useSSL}";
          ssl_verify = "${ifToYesNo v.server.verifySSL}";
          autoconnect = "${ifToYesNo v.server.autoconnect}";
        }'')
        cfg.chatnets
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
              autojoin = "${ifToYesNo cv.autojoin}";
            }'')
            v.channels)
        )
        cfg.chatnets
      );

  serverType =
    types.submodule (
      {name, ...}: {
        options = {
          address = mkOption {
            type = types.str;
            description = "Address of the Chat server.";
          };
          port = mkOption {
            type = types.int;
            default = 6667;
            description = "Port of the Chat server.";
          };
          useSSL = mkOption {
            type = types.bool;
            default = true;
            description = "Whether SSL should be used.";
          };
          verifySSL = mkOption {
            type = types.bool;
            default = true;
            description = "Whether the SSL Certificate should be verified.";
          };
          autoconnect = mkOption {
            type = types.bool;
            default = false;
            description = "Whether irssi connects to the server on launch.";
          };
        };
      }
    );

  channelType =
    types.submodule (
      {name, ...}: {
        options = {
          name = mkOption {
            type = types.str;
            visible = false;
            default = name;
            description = "Name of the channel.";
          };
          autojoin = mkOption {
            type = types.bool;
            default = false;
            description = "Whether to join this channel on connect.";
          };
        };
      }
    );

in

{

  options = {
    programs.irssi = {
      enable = mkOption {
        type = types.bool;
        default = false;
        defaultText = "false";
        description = "Whether to enable the irssi chat client.";
      };

      extraConfig = mkOption {
        default = "";
        description = "These lines are appended to the irssi config.";
        type = types.str;
      };

      aliases = mkOption {
        default = {};
        example = { J = "join"; BYE = "quit";};
        description = "An attribute set that maps aliases to commands.";
        type = types.attrs;
      };

      chatnets = mkOption {
        default = {};
        description = "An attribute set of chat networks.";
        type = types.loaOf (
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
                  description = "Nickname in that chat network.";
                };
                type = mkOption {
                  type = types.str;
                  description = "Type of the chat network.";
                  default = "IRC";
                };
                autoCmd = mkOption {
                  type = types.listOf types.str;
                  default = [];
                  description = "List of commands to execute on connect.";
                };

                server = mkOption {
                  description = "Server settings for the given Chatnet.";
                  type = serverType;
                };

                channels = mkOption {
                  description = "Channels for the given Chatnet.";
                  type = types.loaOf channelType;
                  default = [];
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
