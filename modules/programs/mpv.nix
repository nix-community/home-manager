{ config, lib, pkgs, ... }:

with lib;

let
  inherit (builtins) typeOf stringLength;

  cfg = config.programs.mpv;

  mpvOption = with types; either str (either int (either bool float));
  mpvOptions = with types; attrsOf mpvOption;
  mpvProfiles = with types; attrsOf mpvOptions;
  mpvBindings = with types; attrsOf str;

  renderOption = option:
    rec {
      int = toString option;
      float = int;

      bool = if option then "yes" else "no";

      string = option;
    }.${typeOf option};

  renderOptions = options:
    concatStringsSep "\n"
      (mapAttrsToList
        (name: value:
          let
            rendered = renderOption value;
            length = toString (stringLength rendered);
          in
          "${name}=%${length}%${rendered}")
          options);

  renderProfiles = profiles:
    concatStringsSep "\n"
      (mapAttrsToList
        (name: value: ''
          [${name}]
          ${renderOptions value}
        '')
        profiles);

  renderBindings = bindings:
    concatStringsSep "\n"
      (mapAttrsToList
        (name: value:
          "${name} ${value}")
        bindings);

in {
  options = {
    programs.mpv = {
      enable = mkEnableOption "mpv";

      config = mkOption {
        description = ''
          Configuration written to
          <filename>~/.config/mpv/mpv.conf</filename>. See
          <citerefentry>
            <refentrytitle>mpv</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>
          for the full list of options.
        '';
        type = mpvOptions;
        default = {};
        example = literalExample ''
          {
            profile = "gpu-hq";
            force-window = "yes";
            ytdl-format = "bestvideo+bestaudio";
            cache-default = 4000000;
          }
        '';
      };

      profiles = mkOption {
        description = ''
          Sub-configuration options for specific profiles written to
          <filename>~/.config/mpv/mpv.conf</filename>. See
          <option>programs.mpv.config</option> for more information.
        '';
        type = mpvProfiles;
        default = {};
        example = literalExample ''
          {
            fast = {
              vo = "vdpau";
            };
            "protocol.dvd" = {
              profile-desc = "profile for dvd:// streams";
              alang = "en";
            };
          }
        '';
      };

      bindings = mkOption {
        description = ''
          Input configuration written to
          <filename>~/.config/mpv/input.conf</filename>. See
          <citerefentry>
            <refentrytitle>mpv</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>
          for the full list of options.
        '';
        type = mpvBindings;
        default = {};
        example = literalExample ''
          {
            WHEEL_UP = "seek 10";
            WHEEL_DOWN = "seek -10";
            "Alt+0" = "set window-scale 0.5";
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ pkgs.mpv ];
    }
    (mkIf (cfg.config != {} || cfg.profiles != {}) {
      xdg.configFile."mpv/mpv.conf".text = ''
        ${optionalString (cfg.config != {}) (renderOptions cfg.config)}
        ${optionalString (cfg.profiles != {}) (renderProfiles cfg.profiles)}
      '';
    })
    (mkIf (cfg.bindings != {}) {
      xdg.configFile."mpv/input.conf".text = renderBindings cfg.bindings;
    })
  ]);

  meta.maintainers = with maintainers; [ tadeokondrak ];
}
