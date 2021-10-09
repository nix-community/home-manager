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
  mpvDefaultProfiles = with types; listOf str;

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

  renderDefaultProfiles = profiles:
    renderOptions { profile = concatStringsSep "," profiles; };

  mpvPackage = if cfg.scripts == [ ] then
    cfg.package
  else
    pkgs.wrapMpv pkgs.mpv-unwrapped { scripts = cfg.scripts; };

in {
  options = {
    programs.mpv = {
      enable = mkEnableOption "mpv";

      package = mkOption {
        type = types.package;
        default = pkgs.mpv;
        example = literalExpression
          "pkgs.wrapMpv (pkgs.mpv-unwrapped.override { vapoursynthSupport = true; }) { youtubeSupport = true; }";
        description = ''
          Package providing mpv.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting mpv package.
        '';
      };

      scripts = mkOption {
        type = with types; listOf (either package str);
        default = [ ];
        example = literalExpression "[ pkgs.mpvScripts.mpris ]";
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
        example = literalExpression ''
          {
            profile = "gpu-hq";
            force-window = true;
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
        example = literalExpression ''
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

      defaultProfiles = mkOption {
        description = ''
          Profiles to be applied by default. Options set by them are overridden
          by options set in <xref linkend="opt-programs.mpv.config"/>.
        '';
        type = mpvDefaultProfiles;
        default = [ ];
        example = [ "gpu-hq" ];
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
        example = literalExpression ''
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
      assertions = [{
        assertion = (cfg.scripts == [ ]) || (cfg.package == pkgs.mpv);
        message = ''
          The programs.mpv "package" option is mutually exclusive with "scripts" option.'';
      }];
    }
    {
      home.packages = [ mpvPackage ];
      programs.mpv.finalPackage = mpvPackage;
    }
    (mkIf (cfg.config != { } || cfg.profiles != { }) {
      xdg.configFile."mpv/mpv.conf".text = ''
        ${optionalString (cfg.defaultProfiles != [ ])
        (renderDefaultProfiles cfg.defaultProfiles)}
        ${optionalString (cfg.config != { }) (renderOptions cfg.config)}
        ${optionalString (cfg.profiles != { }) (renderProfiles cfg.profiles)}
      '';
    })
    (mkIf (cfg.bindings != { }) {
      xdg.configFile."mpv/input.conf".text = renderBindings cfg.bindings;
    })
  ]);

  meta.maintainers = with maintainers; [ tadeokondrak thiagokokada ];
}
