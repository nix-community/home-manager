{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.rofi;

  mkValueString = value:
    if isBool value then
      if value then "true" else "false"
    else if isInt value then
      toString value
    else if (value._type or "") == "literal" then
      value.value
    else if isString value then
      ''"${value}"''
    else if isList value then
      "[ ${strings.concatStringsSep "," (map mkValueString value)} ]"
    else
      abort "Unhandled value type ${builtins.typeOf value}";

  mkKeyValue = { sep ? ": ", end ? ";" }:
    name: value:
    "${name}${sep}${mkValueString value}${end}";

  mkRasiSection = name: value:
    if isAttrs value then
      let
        toRasiKeyValue = generators.toKeyValue { mkKeyValue = mkKeyValue { }; };
        # Remove null values so the resulting config does not have empty lines
        configStr = toRasiKeyValue (filterAttrs (_: v: v != null) value);
      in ''
        ${name} {
        ${configStr}}
      ''
    else
      (mkKeyValue {
        sep = " ";
        end = "";
      } name value) + "\n";

  toRasi = attrs: concatStringsSep "\n" (mapAttrsToList mkRasiSection attrs);

  locationsMap = {
    center = 0;
    top-left = 1;
    top = 2;
    top-right = 3;
    right = 4;
    bottom-right = 5;
    bottom = 6;
    bottom-left = 7;
    left = 8;
  };

  primitive = with types; (oneOf [ str int bool rasiLiteral ]);

  # Either a `section { foo: "bar"; }` or a `@import/@theme "some-text"`
  configType = with types;
    (either (attrsOf (either primitive (listOf primitive))) str);

  rasiLiteral = types.submodule {
    options = {
      _type = mkOption {
        type = types.enum [ "literal" ];
        internal = true;
      };

      value = mkOption {
        type = types.str;
        internal = true;
      };
    };
  } // {
    description = "Rasi literal string";
  };

  themeType = with types; attrsOf configType;

  themeName = if (cfg.theme == null) then
    null
  else if (isString cfg.theme) then
    cfg.theme
  else if (isAttrs cfg.theme) then
    "custom"
  else
    removeSuffix ".rasi" (baseNameOf cfg.theme);

  themePath = if (isString cfg.theme) then
    null
  else if (isAttrs cfg.theme) then
    "custom"
  else
    cfg.theme;

in {
  options.programs.rofi = {
    enable = mkEnableOption
      "Rofi: A window switcher, application launcher and dmenu replacement";

    package = mkOption {
      default = pkgs.rofi;
      type = types.package;
      description = ''
        Package providing the <command>rofi</command> binary.
      '';
      example = literalExpression ''
        pkgs.rofi.override { plugins = [ pkgs.rofi-emoji ]; };
      '';
    };

    plugins = mkOption {
      default = [ ];
      type = types.listOf types.package;
      description = ''
        List of rofi plugins to be installed.
      '';
      example = literalExpression "[ pkgs.rofi-calc ]";
    };

    font = mkOption {
      default = null;
      type = types.nullOr types.str;
      example = "Droid Sans Mono 14";
      description = "Font to use.";
    };

    terminal = mkOption {
      default = null;
      type = types.nullOr types.str;
      description = ''
        Path to the terminal which will be used to run console applications
      '';
      example = "\${pkgs.gnome.gnome_terminal}/bin/gnome-terminal";
    };

    cycle = mkOption {
      default = null;
      type = types.nullOr types.bool;
      description = "Whether to cycle through the results list.";
    };

    location = mkOption {
      default = "center";
      type = types.enum (attrNames locationsMap);
      description = "The location rofi appears on the screen.";
    };

    xoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the x-axis in pixels relative to the chosen location.
      '';
    };

    yoffset = mkOption {
      default = 0;
      type = types.int;
      description = ''
        Offset in the y-axis in pixels relative to the chosen location.
      '';
    };

    theme = mkOption {
      default = null;
      type = with types; nullOr (oneOf [ str path themeType ]);
      example = literalExpression ''
        let
          # Use `mkLiteral` for string-like values that should show without
          # quotes, e.g.:
          # {
          #   foo = "abc"; => foo: "abc";
          #   bar = mkLiteral "abc"; => bar: abc;
          # };
          inherit (config.lib.formats.rasi) mkLiteral;
        in {
          "*" = {
            background-color = mkLiteral "#000000";
            foreground-color = mkLiteral "rgba ( 250, 251, 252, 100 % )";
            border-color = mkLiteral "#FFFFFF";
            width = 512;
          };

          "#inputbar" = {
            children = map mkLiteral [ "prompt" "entry" ];
          };

          "#textbox-prompt-colon" = {
            expand = false;
            str = ":";
            margin = mkLiteral "0px 0.3em 0em 0em";
            text-color = mkLiteral "@foreground-color";
          };
        }
      '';
      description = ''
        Name of theme or path to theme file in rasi format or attribute set with
        theme configuration. Available named themes can be viewed using the
        <command>rofi-theme-selector</command> tool.
      '';
    };

    configPath = mkOption {
      default = "${config.xdg.configHome}/rofi/config.rasi";
      defaultText = "$XDG_CONFIG_HOME/rofi/config.rasi";
      type = types.str;
      description = "Path where to put generated configuration file.";
    };

    extraConfig = mkOption {
      default = { };
      example = literalExpression ''
        {
          modi = "drun,emoji,ssh";
          kb-primary-paste = "Control+V,Shift+Insert";
          kb-secondary-paste = "Control+v,Insert";
        }
      '';
      type = configType;
      description = "Additional configuration to add.";
    };

  };

  imports = let
    mkRemovedOptionRofi = option:
      (mkRemovedOptionModule [ "programs" "rofi" option ]
        "Please use a Rofi theme instead.");
  in map mkRemovedOptionRofi [
    "width"
    "lines"
    "borderWidth"
    "rowHeight"
    "padding"
    "separator"
    "scrollbar"
    "fullscreen"
    "colors"
  ];

  config = mkIf cfg.enable {
    assertions =
      [ (hm.assertions.assertPlatform "programs.rofi" pkgs platforms.linux) ];

    lib.formats.rasi.mkLiteral = value: {
      _type = "literal";
      inherit value;
    };

    home.packages = let
      rofiWithPlugins = cfg.package.override
        (old: rec { plugins = (old.plugins or [ ]) ++ cfg.plugins; });
      rofiPackage = if builtins.hasAttr "override" cfg.package then
        rofiWithPlugins
      else
        cfg.package;
    in [ rofiPackage ];

    home.file."${cfg.configPath}".text = toRasi {
      configuration = ({
        font = cfg.font;
        terminal = cfg.terminal;
        cycle = cfg.cycle;
        location = (getAttr cfg.location locationsMap);
        xoffset = cfg.xoffset;
        yoffset = cfg.yoffset;
      } // cfg.extraConfig);
      # @theme must go after configuration but attrs are output in alphabetical order ('@' first)
    } + (optionalString (themeName != null) (toRasi { "@theme" = themeName; }));

    xdg.dataFile = mkIf (themePath != null) (if themePath == "custom" then {
      "rofi/themes/${themeName}.rasi".text = toRasi cfg.theme;
    } else {
      "rofi/themes/${themeName}.rasi".source = themePath;
    });
  };

  meta.maintainers = with maintainers; [ thiagokokada ];
}
