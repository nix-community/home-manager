{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.radare2;

  settingToString = v: if lib.isBool v then lib.boolToString v else toString v;

  # radare2 reads `~/.radare2rc` and `$XDG_CONFIG_HOME/radare2/rc`. A file
  # named `radare2rc` in the XDG directory is not loaded.
  configFile = if config.xdg.enable then "${config.xdg.configHome}/radare2/rc" else ".radare2rc";

  # Merge the plugin packages so that each plugin's data, such as the
  # r2ghidra SLEIGH definitions, stays next to its shared library.
  pluginsDir = pkgs.buildEnv {
    name = "radare2-plugins";
    paths = cfg.plugins;
    pathsToLink = [ "/lib/radare2/plugins" ];
  };

  hasConfig = cfg.settings != { } || cfg.extraConfig != "";
in
{
  meta.maintainers = [ lib.hm.maintainers.sand4rt ];

  options.programs.radare2 = {
    enable = lib.mkEnableOption "radare2";

    package = lib.mkPackageOption pkgs "radare2" { nullable = true; };

    settings = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          float
          str
        ]);
      default = { };
      example = {
        "scr.color" = 2;
        "scr.utf8" = true;
        "asm.describe" = true;
      };
      description = ''
        Evaluation variables written to the radare2 startup script as
        `e key=value` commands. Boolean values are written as `true` or
        `false`.

        See <https://book.rada.re/first_steps/configuration.html> for more
        information, and use [](#opt-programs.radare2.extraConfig) to add
        arbitrary commands.
      '';
    };

    plugins = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.r2ghidra ]";
      description = ''
        radare2 plugin packages. Each package must provide its plugins in
        {file}`lib/radare2/plugins`. They are linked into radare2's user
        plugin directory, {file}`$XDG_DATA_HOME/radare2/plugins`.
      '';
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        eco bobcrawl
      '';
      description = ''
        Extra commands appended to the radare2 startup script after
        [](#opt-programs.radare2.settings).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    # Link per file so that the directory stays writable for `r2pm`.
    xdg.dataFile."radare2/plugins" = lib.mkIf (cfg.plugins != [ ]) {
      source = "${pluginsDir}/lib/radare2/plugins";
      recursive = true;
    };

    home.file.${configFile} = lib.mkIf hasConfig {
      text =
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (name: value: "e ${name}=${settingToString value}") cfg.settings
          ++ lib.optional (cfg.extraConfig != "") (lib.removeSuffix "\n" cfg.extraConfig)
        )
        + "\n";
    };
  };
}
