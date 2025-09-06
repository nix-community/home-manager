/**
  ## Minimal configurations to use this module

  ```nix
  { ... }:
  {
    programs.pianobar = {
      enable = true;
      user = "groovy-tunes@example.com";
      password_command = "cat /run/secrets/pianobar/groovy-tunes";
    };
  }
  ```

  > Note it is recommended to use `sops-nix`, or similar, secrets management
  > solution for providing `programs.pianobar.password_command` value.
*/
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    ;

  inherit (lib.types)
    enum
    float
    int
    listOf
    nonEmptyStr
    nullOr
    path
    pathInStore
    port
    attrs
    submodule
    ;

  filterNullValues = filterAttrs (_name: value: value != null);

  emptyStringOnNullOr = name: value: if value == null then "" else "${name} = ${value}";

  cfg = config.programs.pianobar;
in
{
  options.programs.pianobar = {
    enable = mkEnableOption "Enable pianobar";

    meta = mkOption {
      description = "Metadata about this module";
      default = pkgs.pianobar.meta // {
        maintainers = with lib.maintainers; [
          # S0AndS0
          ## TODO: Trade below for above once PR 427615 or 430772 are merged in NixOS/nixpkgs
          {
            name = "S0AndS0";
            email = "S0AndS0@digital-mercenaries.com";
            github = "S0AndS0";
            githubId = 4116150;
            matrix = "@s0ands0:matrix.org";
          }
        ];
      };
      type = attrs;
    };

    user = mkOption {
      description = "Username or emaill address for Pandora music service authentication";
      example = ''"groovy-tunes@example.com"'';
      type = nonEmptyStr;
      apply = value: "user = ${value}";
    };

    password_command = mkOption {
      description = "Command pianobar will use to access password for Pandora music service authentication";
      example = ''"cat /run/secrets/pianobar/groovy-tunes"'';
      type = nonEmptyStr;
      apply = value: "password_command = ${value}";
    };

    control_proxy = mkOption {
      description = ''
        Non-american users need a proxy to use pandora.com. Only the xmlrpc
        interface will use this proxy.  The music is streamed directly.
      '';
      example = ''"http://user:password@host:port/"'';
      default = null;
      apply = value: emptyStringOnNullOr "control_proxy" value;
      type = nullOr nonEmptyStr;
    };

    keybindings = mkOption {
      description = "Override default CLI keybindings";
      example = ''
        ## Input

        ```nix
        config.programs.pianobar.keybindings = {
          help = "h";
          history = "?";
        };
        ```

        ## Output

        ```conf
        act_help = h
        act_history = ?
        ```
      '';

      default = { };

      apply =
        let
          listKeyValues = mapAttrsToList (name: value: "act_${name} = ${value}");
        in
        attrs: builtins.concatStringsSep "\n" (listKeyValues (filterNullValues attrs));

      type = submodule {
        options = {
          help = mkOption {
            description = "Show keybindings";
            example = ''"?"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songlove = mkOption {
            description = "Love currently played song";
            example = ''"+"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songban = mkOption {
            description = "Ban current track. It will not be played again and can only removed using the pandora.com web interface.";
            example = ''"-"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationaddmusic = mkOption {
            description = "Add more music to current station. You will be asked for a search string. Just follow  the  instructions.";
            example = ''"a"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          bookmark = mkOption {
            description = "Bookmark current song or artist.";
            example = ''"b"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationcreate = mkOption {
            description = "Create new station";
            example = ''"c"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationdelete = mkOption {
            description = "Delete current station.";
            example = ''"d"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songexplain = mkOption {
            description = "Explain why this song is played.";
            example = ''"e"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationaddbygenre = mkOption {
            description = "Add genre station provided by pandora.";
            example = ''"g"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          history = mkOption {
            description = "Show history.";
            example = ''"h"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songinfo = mkOption {
            description = "Print information about currently played song/station.";
            example = ''"i"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          addshared = mkOption {
            description = ''Add shared station by id. id is a very long integer without "sh" at the beginning.'';
            example = ''"j"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          managestation = mkOption {
            description = "Delete artist/song seeds or feedback.";
            example = ''"="'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songnext = mkOption {
            description = "Skip current song.";
            example = ''"n"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songpause = mkOption {
            description = "Pause playback";
            example = ''"S"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songpausetoggle = mkOption {
            description = "Pause/resume playback";
            example = ''"p"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songpausetoggle2 = mkOption {
            description = "Pause/resume playback";
            example = "<Space>";
            default = null;
            type = nullOr nonEmptyStr;
          };
          songplay = mkOption {
            description = "Resume playback";
            example = ''"P"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          quit = mkOption {
            description = "Quit pianobar.";
            example = ''"q"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationrename = mkOption {
            description = "Rename currently played station.";
            example = ''"r"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationchange = mkOption {
            description = "Select another station. The station list can be filtered like most lists by entering a search string instead of a station number.";
            example = ''"s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          songtired = mkOption {
            description = "Ban song for one month.";
            example = ''"t"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          upcoming = mkOption {
            description = "Show next songs in playlist.";
            example = ''"u"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationcreatefromsong = mkOption {
            description = "Create new station from the current song or artist.";
            example = ''"v"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          stationselectquickmix = mkOption {
            description = "Select quickmix stations. You can toggle the selection with 't', select all with 'a' or select none with 'n'.";
            example = ''"x"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          voldown = mkOption {
            description = "Decrease volume.";
            example = ''"("'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          volreset = mkOption {
            description = "Reset volume.";
            example = ''"^"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          volup = mkOption {
            description = "Increase volume.";
            example = ''")"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          settings = mkOption {
            description = "Change Pandora settings.";
            example = ''"|"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
        };
      };
    };

    at_icon = mkOption {
      description = ''Replacement for %@ in station format string. It's " @ " by default.'';
      example = ''"@"'';
      default = null;
      apply = value: emptyStringOnNullOr "at_icon" value;
      type = nullOr nonEmptyStr;
    };

    audio_quality = mkOption {
      description = "Select audio quality.";
      example = ''"low"'';
      default = null;
      apply = value: emptyStringOnNullOr "audio_quality" value;
      type = nullOr (enum [
        "high"
        "medium"
        "low"
      ]);
    };

    audio_pipe = mkOption {
      description = "Stream decoded, raw audio samples to a pipe instead of the default audio device. Use sample_rate to enforce a fixed sample rate";
      example = ''"/path/to/fifo"'';
      default = null;
      apply = value: emptyStringOnNullOr "audio_pipe" value;
      type = nullOr (enum [
        nonEmptyStr
        path
      ]);
    };

    autoselect = mkOption {
      description = "Auto-select last remaining item of filtered list. Currently enabled for station selection only.";
      example = ''"{1,0}"'';
      default = null;
      apply = value: emptyStringOnNullOr "autoselect" value;
      type = nullOr nonEmptyStr;
    };

    autostart_station = mkOption {
      description = "Play this station when starting up. You can get the stationid by pressing i or the  key  you  defined in act_songinfo.";
      example = "123456";
      default = null;
      apply = value: emptyStringOnNullOr "autostart_station" value;
      type = nullOr int;
    };

    bind_to = mkOption {
      description = ''
        This sets the interface name to use as outgoing network
        interface. The name can be an interface name, an IP address, or a
        host name. (from CURLOPT_INTERFACE)

        It can be used as a replacement for control_proxy in conjunction
        with OpenVPN's option route-nopull.
      '';

      example = ''"{if!tunX,host!x.x.x.x,..}"'';
      default = null;
      apply = value: emptyStringOnNullOr "bind_to" value;
      type = nullOr nonEmptyStr;
    };

    buffer_seconds = mkOption {
      description = "Audio buffer size in seconds.";
      example = "5";
      default = null;
      apply = value: emptyStringOnNullOr "buffer_seconds" value;
      type = nullOr int;
    };

    ca_bundle = mkOption {
      description = ''
        Path to CA certifiate bundle, containing the root and intermediate
        certificates required to validate Pandora's SSL certificate.
      '';

      example = ''"/etc/ssl/certs/ca-certificates.crt"'';
      default = null;
      apply = value: if value == null then "" else "ca_bundle = ${value}";
      type = nullOr (enum [
        nonEmptyStr
        path
        pathInStore
      ]);
    };

    event_command = mkOption {
      description = "File that is executed when event occurs";
      example = ''"/home/user/.config/pianobar/eventcmd"'';
      default = null;
      apply = value: emptyStringOnNullOr "event_command" value;
      type = nullOr (enum [
        nonEmptyStr
        path
        pathInStore
      ]);
    };

    fifo = mkOption {
      description = "Location of control fifo";
      example = ''"/home/user/.config/pianobar/cmd"'';
      default = null;
      apply = value: emptyStringOnNullOr "fifo" value;
      type = nullOr (enum [
        nonEmptyStr
        path
      ]);
    };

    format = mkOption {
      description = "";
      example = ''
        ## Input

        ```nix
        config.programs.pianobar.format = {
        };
        ```

        ## Output

        ```conf
        ```
      '';

      default = { };

      apply =
        let
          listKeyValues = mapAttrsToList (name: value: "format_${name} = ${value}");
        in
        attrs: builtins.concatStringsSep "\n" (listKeyValues (filterNullValues attrs));

      type = submodule {
        options = {
          list_song = mkOption {
            description = ''
              Available format characters:

              %i Song number

              %a Song artist

              %t Song title

              %r Rating icon

              %d Song duration

              %@ The at_icon

              %s Song’s station, if not the current station.
            '';

            example = ''"%i) %a - %t%r"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_none = mkOption {
            description = "";
            example = ''"%s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_info = mkOption {
            description = "";
            example = ''"(i) %s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_nowplaying = mkOption {
            description = "";
            example = ''"|> %s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_time = mkOption {
            description = "";
            example = ''"# %s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_err = mkOption {
            description = "";
            example = ''"/!\ %s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_question = mkOption {
            description = "";
            example = ''"[?] %s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          msg_list = mkOption {
            description = "Message format strings.  %s is replaced with the actual message.";
            example = ''"%s"'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          nowplaying_song = mkOption {
            description = ''
              Now playing song message format. Available format characters are:

              %t Song title

              %a Song artist

              %l Album name

              %r Rating icon

              %@ at_icon if station is quickmix, empty otherwise.

              %s Real station name if quickmix

              %u Song detail url
            '';

            example = ''\'\'"%t" by "%a" on "%l"%r%@%s\'\' '';
            default = null;
            type = nullOr nonEmptyStr;
          };
          nowplaying_station = mkOption {
            description = ''
              Now playing station format. Available format characters are:

              %n Station name

              %i Station id
            '';

            example = ''Station "%n" (%i)'';
            default = null;
            type = nullOr nonEmptyStr;
          };
          time = mkOption {
            description = ''
              Time format.

              %e Elapsed time

              %r Remaining time

              %s Sign

              %t Total time
            '';

            example = ''%s%r/%t'';
            default = null;
            type = nullOr nonEmptyStr;
          };
        };
      };
    };

    gain_mul = mkOption {
      description = ''
        Pandora  sends a ReplayGain value with every song. This sets a
        multiplier so that the gain adjustment can be reduced. 0.0 means no
        gain adjustment, 1.0 means full gain adjustment,  values  inbetween
        reduce  the magnitude of gain adjustment.
      '';

      example = ''1.0'';
      default = null;
      apply = value: emptyStringOnNullOr "gain_mul" value;
      type = nullOr float;
      # check = value: value >= 0.0 && value <= 1.0;
    };

    history = mkOption {
      description = "Keep a history of the last n songs (5, by default). You can rate these songs.";
      example = "5";
      default = null;
      apply = value: emptyStringOnNullOr "history" value;
      type = nullOr int;
    };

    love_icon = mkOption {
      description = "Icon for loved songs.";
      example = ''"<3"'';
      default = null;
      apply = value: emptyStringOnNullOr "love_icon" value;
      type = nullOr nonEmptyStr;
    };

    max_retry = mkOption {
      description = "Max failures for several actions before giving up.";
      example = "3";
      default = null;
      apply = value: emptyStringOnNullOr "max_retry" value;
      type = nullOr int;
    };

    proxy = mkOption {
      description = ''
        Use a http proxy. Note that this setting overrides the http_proxy
        environment variable. Only "Basic" http authentication is supported.
      '';
      example = ''"http://user:password@host:port/"'';
      default = null;
      apply = value: emptyStringOnNullOr "proxy" value;
      type = nullOr nonEmptyStr;
    };

    rpc = mkOption {
      description = "RPC host and port";
      example = ''
        ```nix
        options.programs.pianobar.rpc = {
          host = "tuner.pandora.com";
          tls_port = 443;
        };
        ```
      '';

      default = { };

      apply =
        let
          listKeyValues = mapAttrsToList (name: value: "rpc_${name} = ${value}");
        in
        attrs: builtins.concatStringsSep "\n" (listKeyValues (filterNullValues attrs));

      type = submodule {
        options = {
          host = mkOption {
            description = "RPC host";
            example = ''"tuner.pandora.com"'';
            default = null;
            type = nullOr nonEmptyStr;
          };

          tls_port = mkOption {
            description = "RPC TLS port";
            example = "433";
            default = null;
            type = nullOr port;
          };
        };
      };
    };

    sample_rate = mkOption {
      description = "Force fixed output sample rate. The default, 0, uses the stream’s sample rate.";
      example = "0";
      default = null;
      apply = value: emptyStringOnNullOr "sample_rate" value;
      type = nullOr int;
    };

    sort = mkOption {
      description = ''
        Sort  station list by name or type (is quickmix) and name. name_az for
        example sorts by name from a to z, quickmix_01_name_za by type
        (quickmix at the bottom) and name from z to a.
      '';

      example = ''
        ```nix
        options.programs.pianobar.sort = [
          "name_az"
          "name_za"
          "quickmix_01_name_az"
          "quickmix_01_name_za"
          "quickmix_10_name_az"
          "quickmix_10_name_za"
        ];
        ```
      '';

      default = [ ];
      apply =
        value:
        if builtins.length value == 0 then "" else "sort = {${builtins.concatStringsSep ", " value}}";
      type = listOf nonEmptyStr;
    };

    timeout = mkOption {
      description = "Network operation timeout.";
      example = "30";
      default = null;
      apply = value: emptyStringOnNullOr "timeout" value;
      type = nullOr int;
    };

    tired_icon = mkOption {
      description = "Icon for temporarily suspended songs.";
      example = ''"zZ"'';
      default = null;
      apply = value: emptyStringOnNullOr "tired_icon" value;
      type = nullOr nonEmptyStr;
    };

    volume = mkOption {
      description = "Initial volume correction in dB. Usually between -30 and +5.";
      example = "30";
      default = null;
      apply = value: emptyStringOnNullOr "volume" value;
      type = nullOr int;
    };
  };

  config = mkIf cfg.enable {
    home.file."pianobar/config" = {
      target = "${config.xdg.configHome}/pianobar/config";

      text =
        let
          filterValues = filterAttrs (
            name: value: name != "enable" && name != "meta" && value != null && builtins.stringLength value > 0
          );

          filteredValues = attrs: builtins.attrValues (filterValues attrs);
        in
        (builtins.concatStringsSep "\n" (filteredValues cfg)) + "\n";
    };

    home.packages = with pkgs; [
      pianobar
    ];
  };
}
