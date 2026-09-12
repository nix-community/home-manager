{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    filterAttrs
    isAttrs
    isString
    literalExpression
    mkOption
    types
    ;

  cfg = config.programs.rofi;

  extraConfigOverlay = lib.hm.deprecations.mkSettingsOverlay {
    inherit options;
    from = [
      "programs"
      "rofi"
      "extraConfig"
    ];
    to = [
      "programs"
      "rofi"
      "settings"
    ];
  };
  extraConfigKeys = extraConfigOverlay.keys;

  mkValueString =
    value:
    if lib.isBool value then
      if value then "true" else "false"
    else if lib.isInt value then
      toString value
    else if (value._type or "") == "literal" then
      value.value
    else if isString value then
      ''"${value}"''
    else if lib.isList value then
      "[ ${lib.strings.concatStringsSep "," (map mkValueString value)} ]"
    else
      abort "Unhandled value type ${builtins.typeOf value}";

  mkKeyValue =
    {
      sep ? ": ",
      end ? ";",
    }:
    name: value: "${name}${sep}${mkValueString value}${end}";

  isSection = value: isAttrs value && (value._type or "") != "literal";

  toRasiKeyValue =
    attrs:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (
        name: value:
        if isSection value then
          "${name} {\n${toRasiKeyValue (filterAttrs (_: v: v != null) value)}\n}"
        else
          mkKeyValue { } name value
      ) (filterAttrs (_: v: v != null) attrs)
    );

  mkRasiSection =
    name: value:
    if isSection value then
      "${name} {\n${toRasiKeyValue value}\n}\n"
    else
      (mkKeyValue {
        sep = " ";
        end = "";
      } name value)
      + "\n";

  toRasi =
    attrs:
    lib.concatStringsSep "\n" (
      lib.concatMap (lib.mapAttrsToList mkRasiSection) [
        (filterAttrs (n: _: n == "@theme") attrs)
        (filterAttrs (n: _: n == "@import") attrs)
        (removeAttrs attrs [
          "@theme"
          "@import"
        ])
      ]
    );

  configValueType =
    with types;
    (oneOf [
      str
      int
      bool
      rasiLiteral
    ]);

  sectionType = with types; attrsOf (either configValueType (listOf configValueType));

  settingsType =
    with types;
    attrsOf (nullOr (either sectionType (either configValueType (listOf configValueType))));

  rasiLiteral =
    types.submodule {
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
    }
    // {
      description = "Rasi literal string";
    };

  themeName =
    if (cfg.theme == null) then
      null
    else if (isString cfg.theme) then
      cfg.theme
    else if (isAttrs cfg.theme) then
      "custom"
    else
      lib.removeSuffix ".rasi" (baseNameOf cfg.theme);

  themePath =
    if (isString cfg.theme) then
      null
    else if (isAttrs cfg.theme) then
      "custom"
    else
      cfg.theme;

in
{
  meta.maintainers = [ ];

  options.programs.rofi = {
    enable = lib.mkEnableOption "Rofi: A window switcher, application launcher and dmenu replacement";

    package = lib.mkPackageOption pkgs "rofi" {
      example = "pkgs.rofi.override { plugins = [ pkgs.rofi-emoji ]; }";
    };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        Resulting customized rofi package.
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

    theme = mkOption {
      default = null;
      type =
        with types;
        nullOr (oneOf [
          str
          path
          (attrsOf (either sectionType str))
        ]);
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
        {command}`rofi-theme-selector` tool.
      '';
    };

    configPath = mkOption {
      default = "${config.xdg.configHome}/rofi/config.rasi";
      defaultText = "$XDG_CONFIG_HOME/rofi/config.rasi";
      type = types.nonEmptyStr;
      description = "Path where to put generated configuration file.";
    };

    settings = mkOption {
      default = { };
      example = {
        kb-primary-paste = "Control+V,Shift+Insert";
        kb-secondary-paste = "Control+v,Insert";
        "run,drun" = {
          display-name = "open:";
        };
      };
      type = types.submodule (
        { config, ... }:
        let
          extraConfigKeys = config._module.args.rofiExtraConfigKeys;
        in
        {
          freeformType = types.lazyAttrsOf settingsType.nestedTypes.elemType;
          config = {
            _module.args.rofiExtraConfigKeys = lib.mkDefault [ ];
            location = lib.mkIf (!(lib.elem "location" extraConfigKeys)) (lib.mkOptionDefault 0);
            xoffset = lib.mkIf (!(lib.elem "xoffset" extraConfigKeys)) (lib.mkOptionDefault 0);
            yoffset = lib.mkIf (!(lib.elem "yoffset" extraConfigKeys)) (lib.mkOptionDefault 0);
          };
        }
      );
      description = ''
        Settings for the Rasi `configuration` block. See {manpage}`rofi(1)`.
        Use native names and values, including numeric locations and
        `"name:path"` strings for script modes. Use
        `config.lib.formats.rasi.mkLiteral` for unquoted Rasi values.

        Ordinary and per-setting `lib.mkDefault` assignments override values
        supplied through the former modeled options. The deprecated
        `programs.rofi.extraConfig` alias retains its precedence over those
        options.
      '';
    };

  };

  imports = [
    extraConfigOverlay.module
  ]
  ++
    map
      (
        name:
        { config, options, ... }:
        lib.doRename
          {
            from = [
              "programs"
              "rofi"
              name
            ];
            to = [
              "programs"
              "rofi"
              "settings"
              name
            ];
            visible = false;
            warn = true;
            use =
              _:
              cfg.settings.${name} or (
                if
                  lib.elem name [
                    "xoffset"
                    "yoffset"
                  ]
                then
                  0
                else
                  null
              );
            condition =
              options.programs.rofi.${name}.isDefined && options.programs.rofi.${name}.highestPrio <= 1500;
          }
          {
            inherit config;
            # Resolve old definitions first. Priority 1400 lies between caller
            # mkDefault (1000) and the historical option defaults (1500).
            options = lib.recursiveUpdate options (
              lib.setAttrByPath [ "programs" "rofi" name ] {
                highestPrio = 1400;
                definitions =
                  if lib.elem name extraConfigKeys then [ ] else options.programs.rofi.${name}.definitions;
              }
            );
          }
      )
      [
        "font"
        "terminal"
        "cycle"
        "xoffset"
        "yoffset"
      ]
  ++ [
    (
      { config, options, ... }:
      let
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
        changed =
          lib.mkChangedOptionModule [ "programs" "rofi" "location" ] [ "programs" "rofi" "settings" ]
            (
              config:
              lib.optionalAttrs (!(lib.elem "location" extraConfigKeys)) {
                location = lib.mkOverride 1400 locationsMap.${config.programs.rofi.location};
              }
            )
            { inherit config options; };
      in
      changed
      // {
        options = lib.recursiveUpdate changed.options {
          programs.rofi.location.default = "center";
        };
        config = lib.mkIf (options.programs.rofi.location.highestPrio < 1500) changed.config;
      }
    )
    (
      { config, options, ... }:
      let
        changed = lib.mkChangedOptionModule [ "programs" "rofi" "modes" ] [ "programs" "rofi" "settings" ] (
          config:
          lib.optionalAttrs (!(lib.elem "modes" extraConfigKeys)) {
            modes = lib.mkOverride 1400 (
              if config.programs.rofi.modes == [ ] then
                null
              else
                map (mode: if isString mode then mode else "${mode.name}:${mode.path}") config.programs.rofi.modes
            );
          }
        ) { inherit config options; };
      in
      changed
      // {
        options = lib.recursiveUpdate changed.options {
          programs.rofi.modes = {
            default = [ ];
            type =
              with types;
              listOf (
                either str (submodule {
                  options = {
                    name = mkOption {
                      type = str;
                      description = "Name used to reference the custom mode in the mode list.";
                    };
                    path = mkOption {
                      type = str;
                      description = "Executable path for the custom rofi script mode.";
                    };
                  };
                })
              );
          };
        };
        config = lib.mkIf (
          options.programs.rofi.modes.highestPrio < 1500 || config.programs.rofi.modes != [ ]
        ) changed.config;
      }
    )
  ]
  ++
    map
      (option: lib.mkRemovedOptionModule [ "programs" "rofi" option ] "Please use a Rofi theme instead.")
      [
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

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.rofi" pkgs lib.platforms.linux)
    ];

    lib.formats.rasi.mkLiteral = value: {
      _type = "literal";
      inherit value;
    };

    programs.rofi.finalPackage =
      if builtins.hasAttr "override" cfg.package && cfg.plugins != [ ] then
        cfg.package.override (old: {
          plugins = (old.plugins or [ ]) ++ cfg.plugins;
        })
      else
        cfg.package;

    home.packages = [ cfg.finalPackage ];

    # Keep runtime metadata out of getSubOptions. A forced settings root also
    # discards this metadata, restoring the historical numeric defaults.
    programs.rofi.settings =
      let
        old = options.programs.rofi.extraConfig;
      in
      lib.mkIf (old.isDefined && old.highestPrio <= 1500) {
        _module.args.rofiExtraConfigKeys = extraConfigKeys;
      };

    home.file."${cfg.configPath}".text =
      toRasi {
        configuration = cfg.settings;
      }
      # @theme must go after configuration but attrs are output in alphabetical order ('@' first)

      + (lib.optionalString (themeName != null) (toRasi {
        "@theme" = themeName;
      }));

    xdg.dataFile = lib.mkIf (themePath != null) (
      if themePath == "custom" then
        {
          "rofi/themes/${themeName}.rasi".text = toRasi cfg.theme;
        }
      else
        {
          "rofi/themes/${themeName}.rasi".source = themePath;
        }
    );
  };
}
