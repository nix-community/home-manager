{ config, lib, pkgs, ... }:

with lib;

let
  inherit (builtins) typeOf stringLength;

  cfg = config.programs.mpv;

  mpvOption = with types; either str (either int (either bool float));
  mpvOptionDup = with types; either mpvOption (listOf mpvOption);
  mpvOptions = with types; attrsOf mpvOptionDup;
  mpvProfiles = with types; attrsOf mpvOptions;
  mpvBindings = with types; attrsOf str;

  renderOption = option:
    rec {
      int = toString option;
      float = int;

      bool = if option then "yes" else "no";

      string = option;
    }.${typeOf option};

  renderOptionValue = value:
    let
      rendered = renderOption value;
      length = toString (stringLength rendered);
    in "%${length}%${rendered}";

  renderOptions = generators.toKeyValue {
    mkKeyValue =
      generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };

  renderProfiles = generators.toINI {
    mkKeyValue =
      generators.mkKeyValueDefault { mkValueString = renderOptionValue; } "=";
    listsAsDuplicateKeys = true;
  };

  renderBindings = bindings:
    concatStringsSep "\n"
    (mapAttrsToList (name: value: "${name} ${value}") bindings);

  mpvPackage = if cfg.scripts == [ ] then
    pkgs.mpv
  else
    pkgs.wrapMpv pkgs.mpv-unwrapped { scripts = cfg.scripts; };

in {
  options = {
    programs.mpv = {
      enable = mkEnableOption "mpv";

      package = mkOption {
        type = types.package;
        readOnly = true;
        description = ''
          Resulting mpv package.
        '';
      };

      scripts = mkOption {
        type = with types; listOf (either package str);
        default = [ ];
        example = literalExample "[ pkgs.mpvScripts.mpris ]";
        description = ''
          List of scripts to use with mpv.
        '';
      };

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
        default = { };
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
        default = { };
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
        default = { };
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
      home.packages = [ mpvPackage ];
      programs.mpv.package = mpvPackage;
    }
    (mkIf (cfg.config != { } || cfg.profiles != { }) {
      xdg.configFile."mpv/mpv.conf".text = ''
        ${optionalString (cfg.config != { }) (renderOptions cfg.config)}
        ${optionalString (cfg.profiles != { }) (renderProfiles cfg.profiles)}
      '';
    })
    (mkIf (cfg.bindings != { }) {
      xdg.configFile."mpv/input.conf".text = renderBindings cfg.bindings;
    })
  ]);

  meta.maintainers = with maintainers; [ tadeokondrak ];
}
