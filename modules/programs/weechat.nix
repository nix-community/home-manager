{ config, pkgs, lib, ... }:
with lib;
let
  settingType = types.attrsOf (types.either cfgType settingType);
  flatConfig = attrs:
    let
      deep = mapAttrsRecursive
        (path: value: nameValuePair (concatStringsSep "." path) value) attrs;
      recurse = value:
        if isAttrs value && !value ? value then
          concatMap recurse (builtins.attrValues value)
        else
          [ value ];
    in listToAttrs (recurse deep);
  cfgType = types.either types.str (types.either types.bool types.int);
  cfg = config.programs.weechat;
  scfg = config.services.weechat;
  drvAttr = types.either types.str types.package;
  drvAttrsFor = packages: map (d: if isString d then packages.${d} else d);
  configStr = v:
    if isString v then
      ''"${v}"''
    else if isBool v then
      (if v then "on" else "off")
    else if isInt v then
      toString v
    else
      throw "unknown weechat config value ${toString v}";
  makeConfText = attr:
    lib.concatStringsSep "\n" (lib.attrsets.mapAttrsToList (name: value:
      ''
        [${name}]
      '' + lib.concatStringsSep "\n"
      (lib.attrsets.mapAttrsToList (k: v: "${k} = ${configStr v}")
        (flatConfig value))) attr);
  writeConfig = attr: weechatDir:
    lib.attrsets.mapAttrs (name: value: {
      text = makeConfText value;
      target = "${
          removePrefix config.home.homeDirectory cfg.homeDirectory
        }/${name}.conf";
    }) (lib.attrsets.mapAttrs' (name: value:
      lib.attrsets.nameValuePair ("${weechatDir}/" + name + ".conf") value)
      attr);
  configure = { availablePlugins, ... }: {
    plugins = with availablePlugins;
      optional cfg.plugins.perl.enable (perl)
      ++ optional cfg.plugins.python.enable
      (python.withPackages (ps: drvAttrsFor ps cfg.plugins.python.packages))
      ++ optional (cfg.environment != { }) {
        # dummy for inserting env vars into wrapper script
        pluginFile = "";
        extraEnv = concatStringsSep "\n"
          (mapAttrsToList (k: v: "export ${k}=${escapeShellArg v}")
            cfg.environment);
      };
    scripts = drvAttrsFor pkgs.weechatScripts cfg.scripts;
    inherit (cfg) init;
  };
  pythonOverride = { python3Packages = cfg.pythonPackages; };
  defaultHomeDirectory = "${config.home.homeDirectory}/.weechat";
  weechatrc = "${config.home.homeDirectory}/${
      config.xdg.configFile."weechat/weechatrc".target
    }";
in {
  options.programs.weechat = {
    enable = mkEnableOption "weechat";

    package = mkOption {
      type = types.package;
      defaultText = "pkgs.weechat";
      default = cfg.packageWrapper cfg.packageUnwrapped { inherit configure; };
    };

    packageUnwrapped = mkOption {
      type = types.package;
      defaultText = "pkgs.weechat-unwrapped";
      default = pkgs.weechat-unwrapped.override pythonOverride;
    };

    packageWrapper = mkOption {
      type = types.unspecified;
      defaultText = "pkgs.wrapWeechat";
      default = pkgs.wrapWeechat.override pythonOverride;
    };

    pythonPackages = mkOption {
      type = types.unspecified;
      defaultText = "pkgs.python3Packages";
      example = literalExpression "pkgs.pythonPackages";
      default = pkgs.python3Packages;
    };

    plugins = {
      perl = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
      };
      python = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };

        packages = mkOption {
          type = types.listOf drvAttr;
          default = [ ];
          description =
            "Attributes or derivations from pythonPackages that scripts might depend on";
          example = [ "weechat-matrix" ];
        };
      };
    };

    scripts = mkOption {
      type = types.listOf drvAttr;
      description = "Attributes or derivations from pkgs.weechatScripts";
      default = [ ];
      example = [ "weechat-matrix" "autosort" ];
    };

    init = mkOption {
      type = types.lines;
      description = "Commands to run on startup";
      default = "";
    };

    source = mkOption {
      type = types.listOf types.path;
      description = "Files to source on startup";
      default = [ ];
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      description = "Extra environment variables";
      default = { };
    };

    homeDirectory = mkOption {
      type = types.path;
      description = "Weechat home config directory";
      default = if cfg.mutableConfig then
        defaultHomeDirectory
      else
        "${config.xdg.configHome}/weechat";
      defaultText = "~/.weechat or $XDG_CONFIG_HOME/weechat if immutable";
      example = literalExpression "\${config.xdg.dataHome}/weechat";
    };

    config = mkOption {
      type = settingType;
      description = "Weechat configuration settings";
      default = { };
    };

    mutableConfig = mkOption {
      type = types.bool;
      description =
        "Allow imperative modification of the weechat config via /set";
      default = true;
    };

    liveReload = mkOption {
      type = types.bool;
      description = "Apply settings to the running weechat instance on switch";
      default = true;
    };
  };
  options.services.weechat = {
    enable = mkEnableOption "weechat tmux session";

    sessionName = mkOption {
      type = types.str;
      description = "Name of the tmux session for weechat";
      default = "irc";
    };

    tmuxSocket = mkOption {
      type = with types; nullOr str;
      default = null;
      example = "tmux";
      description =
        "If set, the service will store the named server socket under `programs.weechat.homeDirectory`";
    };

    tmuxPackage = mkOption {
      type = types.package;
      description = "tmux package";
      default = pkgs.tmux;
      defaultText = "pkgs.tmux";
    };

    binary = mkOption {
      type = types.path;
      description = "Binary to execute";
      example = literalExpression
        "\${config.programs.weechat.package}/bin/weechat-headless";
      default = "${cfg.package}/bin/weechat";
      defaultText = "\${config.programs.weechat.package}/bin/weechat";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    systemd.user.services = mkIf scfg.enable {
      weechat-tmux = {
        Unit = {
          Description = "Weechat tmux session";
          After = [ "network.target" ];
        };
        Service = let
          tmuxFlags = [ "-2" ] ++ optionals (scfg.tmuxSocket != null) [
            "-S"
            "${cfg.homeDirectory}/${scfg.tmuxSocket}"
          ];
          sessionFlags = [
            "-d"
            "-e"
            "WEECHAT_HOME=${cfg.homeDirectory}"
            "-s"
            scfg.sessionName
            scfg.binary
          ];
          tmuxFlagsStr = concatStringsSep " " tmuxFlags;
          sessionFlagsStr = concatStringsSep " " sessionFlags;
        in {
          Type = "oneshot";
          Environment = optional
            (scfg.tmuxSocket == null && config.programs.tmux.secureSocket)
            "TMUX_TMPDIR=%t";
          RemainAfterExit = true;
          X-RestartIfChanged = false;
          ExecStart =
            "${scfg.tmuxPackage}/bin/tmux ${tmuxFlagsStr} new-session ${sessionFlagsStr}";
          ExecStop =
            "${scfg.tmuxPackage}/bin/tmux ${tmuxFlagsStr} kill-session -t ${scfg.sessionName}";
        };
        Install.WantedBy = [ "default.target" ];
      };
    };

    home.file = mkIf (!cfg.mutableConfig) (writeConfig cfg.config
      (removePrefix config.home.homeDirectory cfg.homeDirectory));
    xdg.configFile."weechat/weechatrc" =
      mkIf ((cfg.mutableConfig || cfg.liveReload) && cfg.config != { }) {
        text = concatStringsSep "\n"
          (mapAttrsToList (k: v: "/set ${k} ${configStr v}")
            (flatConfig cfg.config));
        # NOTE: this doesn't include/re-run init commands (should it?)
        onChange = mkIf cfg.liveReload ''
          if [[ -p "${cfg.homeDirectory}/weechat_fifo" ]]; then
            echo "Refreshing weechat settings..." >&2
            ${
              if cfg.mutableConfig then
                ''sed "s-^/-*/-" "${weechatrc}"''
              else
                ''echo "*/reload"''
            } | timeout 3 tee "${cfg.homeDirectory}/weechat_fifo" > /dev/null || true
          fi
        '';
      };
    programs.weechat = {
      environment = mkIf (cfg.homeDirectory != defaultHomeDirectory) {
        WEECHAT_HOME = cfg.homeDirectory;
      };
      source = [ (mkIf (cfg.mutableConfig && cfg.config != { }) weechatrc) ];
      init =
        concatMapStringsSep "\n" (f: "/exec -sh -norc -oc cat ${f}") cfg.source;
    };
  };
}
