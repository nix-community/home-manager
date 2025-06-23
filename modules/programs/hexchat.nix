{
  config,
  pkgs,
  lib,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    types
    ;

  cfg = config.programs.hexchat;

  channelOptions = types.submodule {
    options = {
      autoconnect = mkOption {
        type = with types; nullOr bool;
        default = false;
        description = "Autoconnect to network.";
      };

      connectToSelectedServerOnly = mkOption {
        type = with types; nullOr bool;
        default = true;
        description = "Connect to selected server only.";
      };

      bypassProxy = mkOption {
        type = with types; nullOr bool;
        default = true;
        description = "Bypass proxy.";
      };

      forceSSL = mkOption {
        type = with types; nullOr bool;
        default = false;
        description = "Use SSL for all servers.";
      };

      acceptInvalidSSLCertificates = mkOption {
        type = with types; nullOr bool;
        default = false;
        description = "Accept invalid SSL certificates.";
      };

      useGlobalUserInformation = mkOption {
        type = with types; nullOr bool;
        default = false;
        description = "Use global user information.";
      };
    };
  };

  modChannelOption =
    with types;
    submodule {
      options = {
        autojoin = mkOption {
          type = listOf str;
          default = [ ];
          example = [
            "#home-manager"
            "#linux"
            "#nix"
          ];
          description = "Channels list to autojoin on connecting to server.";
        };

        charset = mkOption {
          type = nullOr str;
          default = null;
          example = "UTF-8 (Unicode)";
          description = "Character set.";
        };

        commands = mkOption {
          type = listOf str;
          default = [ ];
          example = literalExpression ''[ "ECHO Greetings fellow Nixer! ]'';
          description = "Commands to be executed on connecting to server.";
        };

        loginMethod = mkOption {
          type = nullOr (enum (lib.attrNames loginMethodMap));
          default = null;
          description = ''
            The login method. The allowed options are:

            `null`
            :  Default

            `"nickServMsg"`
            :  NickServ (`/MSG NickServ` + password)

            `"nickServ"`
            :  NickServ (`/NICKSERV` + password)

            `"challengeAuth"`
            :  Challenge Auth (username + password)

            `"sasl"`
            :  SASL (username + password)

            `"serverPassword"`
            :  Server password (`/PASS` password)

            `"saslExternal"`
            :  SASL EXTERNAL (cert)

            `"customCommands"`
            : Use "commands" field for auth. For example
              ```nix
              commands = [ "/msg NickServ IDENTIFY my_password" ]
              ```
          '';
        };

        nickname = mkOption {
          type = nullOr str;
          default = null;
          description = "Primary nickname.";
        };

        nickname2 = mkOption {
          type = nullOr str;
          default = null;
          description = "Secondary nickname.";
        };

        options = mkOption {
          type = nullOr channelOptions;
          default = null;
          example = {
            autoconnect = true;
            useGlobalUserInformation = true;
          };
          description = "Channel options.";
        };

        password = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Password to use. Note this password will be readable by all user's
            in the Nix store.
          '';
        };

        realName = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            Real name. Is used to populate the real name field that appears when
            someone uses the `WHOIS` command on your nick.
          '';
        };

        userName = mkOption {
          type = nullOr str;
          default = null;
          description = ''
            User name. Part of your `user@host` hostmask that
            appears to other on IRC.
          '';
        };

        servers = mkOption {
          type = listOf str;
          default = [ ];
          example = [ "irc.oftc.net" ];
          description = "IRC Server Address List.";
        };
      };
    };

  transformField = k: v: if (v != null) then "${k}=${v}" else null;

  listChar = c: l: if l != [ ] then lib.concatMapStringsSep "\n" (transformField c) l else null;

  computeFieldsValue =
    channel:
    let
      ifTrue = p: n: if p then n else 0;
      result =
        with channel.options;
        lib.foldl' (a: b: a + b) 0 [
          (ifTrue (!connectToSelectedServerOnly) 1)
          (ifTrue useGlobalUserInformation 2)
          (ifTrue forceSSL 4)
          (ifTrue autoconnect 8)
          (ifTrue (!bypassProxy) 16)
          (ifTrue acceptInvalidSSLCertificates 32)
        ];
    in
    toString (if channel.options == null then 0 else result);

  loginMethodMap = {
    nickServMsg = 1;
    nickServ = 2;
    challengeAuth = 4;
    sasl = 6;
    serverPassword = 7;
    customCommands = 9;
    saslExternal = 10;
  };

  loginMethod =
    channel:
    transformField "L" (
      lib.optionalString (channel.loginMethod != null) (toString loginMethodMap.${channel.loginMethod})
    );

  # Note: Missing option `D=`.
  transformChannel =
    channelName:
    let
      channel = cfg.channels.${channelName};
    in
    lib.concatStringsSep "\n" (
      lib.remove null [
        "" # Leave a space between one server and another
        (transformField "N" channelName)
        (loginMethod channel)
        (transformField "E" channel.charset)
        (transformField "F" (computeFieldsValue channel))
        (transformField "I" channel.nickname)
        (transformField "i" channel.nickname2)
        (transformField "R" channel.realName)
        (transformField "U" channel.userName)
        (transformField "P" channel.password)
        (listChar "S" channel.servers)
        (listChar "J" channel.autojoin)
        (listChar "C" channel.commands)
      ]
    );

in
{
  meta.maintainers = with lib.maintainers; [ thiagokokada ];

  options.programs.hexchat = {
    enable = lib.mkEnableOption "HexChat, a graphical IRC client";

    package = lib.mkPackageOption pkgs "hexchat" { nullable = true; };

    channels = mkOption {
      type = types.attrsOf modChannelOption;
      default = { };
      example = literalExpression ''
        {
          oftc = {
            autojoin = [
              "#home-manager"
              "#linux"
            ];
            charset = "UTF-8 (Unicode)";
            commands = [
              "ECHO Buzz Lightyear sent you a message: 'To Infinity... and Beyond!'"
            ];
            loginMethod = sasl;
            nickname = "my_nickname";
            nickname2 = "my_secondchoice";
            options = {
              acceptInvalidSSLCertificates = false;
              autoconnect = true;
              bypassProxy = true;
              connectToSelectedServerOnly = true;
              useGlobalUserInformation = false;
              forceSSL = false;
            };
            password = "my_password";
            realName = "my_realname";
            servers = [
              "irc.oftc.net"
            ];
            userName = "my_username";
          };
        }'';
      description = ''
        Configures {file}`$XDG_CONFIG_HOME/hexchat/servlist.conf`.
      '';
    };

    settings = mkOption {
      default = null;
      type = types.nullOr (types.attrsOf types.str);
      example = literalExpression ''
        {
          irc_nick1 = "mynick";
          irc_username = "bob";
          irc_realname = "Bart Simpson";
          text_font = "Monospace 14";
        };
      '';
      description = ''
        Configuration for {file}`$XDG_CONFIG_HOME/hexchat/hexchat.conf`, see
        <https://hexchat.readthedocs.io/en/latest/settings.html#list-of-settings>
        for supported values.
      '';
    };

    overwriteConfigFiles = mkOption {
      type = types.nullOr types.bool;
      default = false;
      description = ''
        Enables overwriting HexChat configuration files
        ({file}`hexchat.conf`, {file}`servlist.conf`).
        Any existing HexChat configuration will be lost. Make sure to back up
        any previous configuration before enabling this.

        Enabling this setting is recommended, because everytime HexChat
        application is closed it overwrites Nix/Home Manager provided
        configuration files, causing:

        1. Nix/Home Manager provided configuration to be out of sync with
           actual active HexChat configuration.
        2. Nix/Home Manager updates to be blocked until configuration files are
           manually removed.
      '';
    };

    theme = mkOption {
      type = types.nullOr types.package;
      default = null;
      example = literalExpression ''
        source = pkgs.fetchzip {
          url = "https://dl.hexchat.net/themes/Monokai.hct#Monokai.zip";
          sha256 = "sha256-WCdgEr8PwKSZvBMs0fN7E2gOjNM0c2DscZGSKSmdID0=";
          stripRoot = false;
        };
      '';
      description = ''
        Theme package for HexChat. Expects a derivation containing decompressed
        theme files. Note, `.hct` files are actually ZIP files,
        as seen in example.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.hexchat" pkgs lib.platforms.linux)
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."hexchat" = mkIf (cfg.theme != null) {
      source = cfg.theme;
      recursive = true;
    };

    xdg.configFile."hexchat/hexchat.conf" = mkIf (cfg.settings != null) {
      force = cfg.overwriteConfigFiles;
      text = lib.concatMapStringsSep "\n" (x: x + " = " + cfg.settings.${x}) (lib.attrNames cfg.settings);
    };

    xdg.configFile."hexchat/servlist.conf" = mkIf (cfg.channels != { }) {
      force = cfg.overwriteConfigFiles;
      # Final line breaks is required to avoid cropping last field value.
      text = lib.concatMapStringsSep "\n" transformChannel (lib.attrNames cfg.channels) + "\n\n";
    };
  };
}
