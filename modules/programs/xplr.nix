{ config, lib, pkgs, ... }:
let
  inherit (lib)
    types mkIf mkOption mkEnableOption mkPackageOption literalExpression;

  cfg = config.programs.xplr;

  initialConfig = ''
    version = '${cfg.package.version}'
  '';

  # If `value` is a Nix store path, create the symlink `/nix/store/newhash/${name}/*` 
  # to `/nix/store/oldhash/*` and returns `/nix/store/newhash`.
  wrapPlugin = name: value:
    if lib.isStorePath value then
      pkgs.symlinkJoin {
        name = name;
        paths = [ value ];
        postBuild = ''
          mkdir '${name}'
          mv $out/* '${name}/'
          mv '${name}' $out/
        '';
      }
    else
      builtins.dirOf value;

  makePluginSearchPath = p: "${p}/?/init.lua;${p}/?.lua";

  pluginPath = if cfg.plugins != { } then
    let
      wrappedPlugins = lib.mapAttrsToList wrapPlugin cfg.plugins;
      searchPaths = map makePluginSearchPath wrappedPlugins;
      pluginSearchPath = lib.concatStringsSep ";" searchPaths;
    in (''
      package.path = "${pluginSearchPath};" .. package.path
    '')
  else
    "\n";

  # We provide a default version line within the configuration file, which is
  # obtained from the package's attributes. Merge the initial configFile, a
  # mapped list of plugins and then the user defined configuration to obtain
  # the final configuration.
  configFile = initialConfig + pluginPath + cfg.extraConfig;
in {
  meta.maintainers = [ lib.maintainers.NotAShelf ];

  options.programs.xplr = {
    enable = mkEnableOption "xplr, terminal UI based file explorer";

    package = mkPackageOption pkgs "xplr" { };

    plugins = mkOption {
      type = with types; nullOr (attrsOf (either package str));
      default = { };
      defaultText = literalExpression "{ }";
      description = ''
        An attribute set of plugin paths to be added to the [package.path]<https://www.lua.org/manual/5.4/manual.html#pdf-package.path> of the {file}`~/config/xplr/init.lua` configuration file.

        Must be a package or string representing the plugin directory's path. 
        If the path string is not absolute, it will be relative to {file}`$XDG_CONFIG_HOME/xplr/init.lua`.
      '';
      example = literalExpression ''
        {
          wl-clipboard = fetchFromGitHub {
            owner = "sayanarijit";
            repo = "wl-clipboard.xplr";
            rev = "a3ffc87460c5c7f560bffea689487ae14b36d9c3";
            hash = "sha256-I4rh5Zks9hiXozBiPDuRdHwW5I7ppzEpQNtirY0Lcks=";
          }
          local-plugin = "/home/user/.config/plugins/local-plugin";
        };
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      example = literalExpression ''
        require("wl-clipboard").setup {
          copy_command = "wl-copy -t text/uri-list",
          paste_command = "wl-paste",
          keep_selection = true,
        }
      '';
      description = ''
        Extra xplr configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."xplr/init.lua".source =
      pkgs.writeText "init.lua" configFile;
  };
}
