# Home Manager module for OpenClaw's per-user gateway runtime.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.openclaw;

  jsonFormat = pkgs.formats.json { };
  settingsMergeFilter = pkgs.writeText "openclaw-settings-merge.jq" (import ./settings-merge.nix);
  declaredSettingsFile = jsonFormat.generate "openclaw-declared-settings.json" cfg.settings;
  hasSettings = cfg.settings != { };
  liveConfigPath = "${config.home.homeDirectory}/.openclaw/openclaw.json";
  gatewayArgs = [
    "${cfg.package}/bin/openclaw"
    "gateway"
    "run"
  ]
  ++ lib.optionals (cfg.gateway.port != null) [
    "--port"
    (toString cfg.gateway.port)
  ]
  ++ [
    "--tailscale"
    (if cfg.gateway.tailscale then "on" else "off")
  ];

  openclawSettingsCommand =
    let
      prepareDestination = ''
        live_dst=${lib.escapeShellArg liveConfigPath}
        declared=${lib.escapeShellArg (toString declaredSettingsFile)}
        mkdir -p "$(dirname "$live_dst")"
      '';

      mergeSettings = ''
        tmp=$(mktemp "''${TMPDIR:-/tmp}/openclaw-settings.XXXXXX")
        live_src="$live_dst"

        if [ -L "$live_dst" ]; then
          live_src=$(mktemp "''${TMPDIR:-/tmp}/openclaw-live-settings.XXXXXX")
          if [ -e "$live_dst" ]; then
            cp "$live_dst" "$live_src"
          else
            install -m 0600 ${pkgs.writeText "empty-openclaw.json" "{}"} "$live_src"
          fi
          rm -f "$live_dst"
        fi

        if [ ! -e "$live_src" ]; then
          install -m 0600 ${pkgs.writeText "empty-openclaw.json" "{}"} "$live_src"
        fi

        if ! ${pkgs.jq}/bin/jq empty "$live_src" >/dev/null 2>&1; then
          backup="$live_dst.invalid.$(date +%Y%m%d%H%M%S)"
          cp "$live_src" "$backup"
          rm -f "$tmp"
          if [ "$live_src" != "$live_dst" ]; then
            rm -f "$live_src"
          fi
          echo "Invalid OpenClaw JSON in $live_dst; backed up to $backup" >&2
          exit 1
        fi

        ${pkgs.jq}/bin/jq -s -f ${lib.escapeShellArg (toString settingsMergeFilter)} "$live_src" "$declared" > "$tmp"
        install -m 0600 "$tmp" "$live_dst"
        rm -f "$tmp"
        if [ "$live_src" != "$live_dst" ]; then
          rm -f "$live_src"
        fi
      '';

      replaceSettings = ''
        if [ -L "$live_dst" ]; then
          rm -f "$live_dst"
        fi
        install -m 0600 "$declared" "$live_dst"
      '';
    in
    lib.optionalString hasSettings ''
      ${prepareDestination}
      ${if cfg.mutableSettings then mergeSettings else replaceSettings}
    '';
in
{
  meta.maintainers = [ lib.hm.maintainers.nikhilmaddirala ];

  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw gateway user service and runtime files";

    package = lib.mkPackageOption pkgs "openclaw" { };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = ''
        Nix-declared OpenClaw settings. When empty, Home Manager does not manage
        OpenClaw's config file. When non-empty, Home Manager writes the
        declared settings to {file}`~/.openclaw/openclaw.json`, using
        {option}`services.openclaw.mutableSettings` to choose between preserving
        or replacing existing runtime settings.
      '';
    };

    mutableSettings = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Whether OpenClaw's config file may retain settings written outside Home
        Manager. When enabled, Home Manager merges declared settings into the
        live {file}`~/.openclaw/openclaw.json` file while preserving unknown
        runtime keys. When disabled, Home Manager replaces that file with the
        declared settings.
      '';
    };

    gateway = {
      port = lib.mkOption {
        type = lib.types.nullOr lib.types.port;
        default = null;
        description = "Optional loopback port for this user's OpenClaw gateway. When unset, OpenClaw's CLI default is used.";
      };

      tailscale = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether the gateway should use OpenClaw's built-in Tailscale exposure.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    home.activation.openclawSettings = lib.mkIf (openclawSettingsCommand != "") (
      lib.hm.dag.entryAfter [ "writeBoundary" ] openclawSettingsCommand
    );

    systemd.user.services.openclaw-gateway = {
      Unit = {
        Description = "OpenClaw gateway";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };

      Service = {
        Type = "simple";
        WorkingDirectory = config.home.homeDirectory;
        Environment = [
          "PATH=${config.home.profileDirectory}/bin:/run/current-system/sw/bin:/usr/bin:/bin"
        ];
        ExecStart = lib.escapeShellArgs gatewayArgs;
        Restart = "always";
        RestartSec = "10s";
      };

      Install.WantedBy = [ "default.target" ];
    };

    launchd.agents.openclaw-gateway = {
      enable = true;
      config = {
        ProgramArguments = gatewayArgs;
        WorkingDirectory = config.home.homeDirectory;
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  };
}
