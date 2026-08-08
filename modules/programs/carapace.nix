{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.carapace;
  bin = lib.getExe cfg.package;

  # `ignoreCase` is a deprecated shorthand for CARAPACE_MATCH = "1"; using it
  # together with `environmentVariables.CARAPACE_MATCH` is rejected by the
  # assertion below.
  envVars = cfg.environmentVariables // lib.optionalAttrs cfg.ignoreCase { CARAPACE_MATCH = "1"; };

  setArgs = lib.concatLists (
    lib.mapAttrsToList (k: v: [
      "--set"
      k
      v
    ]) envVars
  );
in
{
  meta.maintainers = with lib.maintainers; [
    weathercold
    bobvanderlinden
  ];

  options.programs.carapace = {
    enable = lib.mkEnableOption "carapace, a multi-shell multi-command argument completer";

    package = lib.mkPackageOption pkgs "carapace" { };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    ignoreCase = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable case-insensitive matching for carapace completions.
        Equivalent to setting
        {option}`programs.carapace.environmentVariables.CARAPACE_MATCH` to
        `1`.

        ::: {.warning}
        This option is deprecated and will be removed in a future release.
        Use {option}`programs.carapace.environmentVariables.CARAPACE_MATCH`
        instead.
        :::
      '';
    };

    environmentVariables = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        CARAPACE_MATCH = "1";
        CARAPACE_EXCLUDES = "wt";
      };
      description = ''
        Environment variables to bake into the {command}`carapace` binary
        (e.g. {env}`CARAPACE_MATCH`, {env}`CARAPACE_EXCLUDES`). Keys are full
        variable names — no prefix is added — mirroring
        {option}`home.sessionVariables`.

        The variables are applied by wrapping the binary with
        {command}`makeWrapper`, so they take effect both at completion time and
        during the build-time {command}`carapace --list` used to disable fish's
        built-in completions for fish < 4.0. This is preferable to setting the
        same variables via {option}`home.sessionVariables`, which would neither
        influence that build-time {command}`--list` nor scope the variables to
        the carapace process.

        Note that {env}`CARAPACE_BRIDGES` and {env}`CARAPACE_EXCLUDES` change
        which completers carapace registers: {env}`CARAPACE_BRIDGES` may
        require running {command}`carapace --clear-cache` after a change and
        notably expands the build-time completion list (and thus the number of
        completion files generated for fish < 4.0), while the remaining
        variables only affect runtime behaviour (matching, styling, …) and do
        not touch the cache.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    warnings = lib.optional cfg.ignoreCase ''
      `programs.carapace.ignoreCase' is deprecated and will be removed in a
      future release. Please use `programs.carapace.environmentVariables.CARAPACE_MATCH'
      (set to "1") instead.
    '';

    assertions = [
      {
        assertion = !(cfg.ignoreCase && cfg.environmentVariables ? CARAPACE_MATCH);
        message = ''
          `programs.carapace.ignoreCase' must not be used together with
          `programs.carapace.environmentVariables.CARAPACE_MATCH' because
          `ignoreCase' is a deprecated shorthand for
          `environmentVariables.CARAPACE_MATCH = "1"'. Please set only one.
        '';
      }
    ];

    programs.carapace.package = lib.mkIf (envVars != { }) (
      pkgs.symlinkJoin {
        name = "carapace";
        paths = [ pkgs.carapace ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/carapace ${lib.escapeShellArgs setArgs}
        '';
        meta.mainProgram = "carapace";
      }
    );

    home.packages = [ cfg.package ];

    programs = {
      bash.initExtra = lib.mkIf cfg.enableBashIntegration ''
        source <(${bin} _carapace bash)
      '';

      zsh.initContent = lib.mkIf cfg.enableZshIntegration ''
        source <(${bin} _carapace zsh)
      '';

      fish.interactiveShellInit = lib.mkIf cfg.enableFishIntegration ''
        ${bin} _carapace fish | source
      '';

      nushell = lib.mkIf cfg.enableNushellIntegration {
        extraConfig = ''
          source ${
            pkgs.runCommand "carapace-nushell-config.nu" { } ''
              ${bin} _carapace nushell | sed 's|"/homeless-shelter|$"($env.HOME)|g' >> "$out"
            ''
          }
        '';
      };
    };

    xdg.configFile =
      lib.mkIf
        (
          config.programs.fish.enable
          && cfg.enableFishIntegration
          && lib.versionOlder config.programs.fish.package.version "4.0.0"
        )
        (
          # Convert the entries from `carapace --list` to empty
          # xdg.configFile."fish/completions/NAME.fish" entries.
          #
          # This is to disable fish builtin completion for each of the
          # carapace-supported completions.
          #
          # This is necessary for carapace to properly work with fish version < 4.0b1.
          #
          # It is in line with the instructions from
          # carapace-bin:
          #
          #   carapace --list | awk '{print $1}' | xargs -I{} touch ~/.config/fish/completions/{}.fish
          #
          # See https://carapace-sh.github.io/carapace-bin/setup.html#fish
          let
            carapaceListFile =
              pkgs.runCommandLocal "carapace-list"
                {
                  buildInputs = [ cfg.package ];
                }
                ''
                  ${bin} --list > $out
                '';
          in
          lib.pipe carapaceListFile [
            lib.fileContents
            (lib.splitString "\n")
            (map (builtins.match "^([a-z0-9-]+) .*"))
            (builtins.filter (match: match != null && (builtins.length match) > 0))
            (map (match: builtins.head match))
            (map (name: {
              name = "fish/completions/${name}.fish";
              value = {
                text = "";
              };
            }))
            builtins.listToAttrs
          ]
        );
  };
}
