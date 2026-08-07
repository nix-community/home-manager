{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.carapace;
  finalPackage =
    if cfg.environment == { } && cfg.extraPackages == [ ] then
      cfg.package
    else
      let
        wrapperArgs = lib.flatten (
          lib.mapAttrsToList (name: value: [
            "--set"
            "CARAPACE_${lib.toUpper name}"
            value
          ]) cfg.environment
          ++ lib.optional (cfg.extraPackages != [ ]) [
            "--suffix"
            "PATH"
            ":"
            (lib.makeBinPath cfg.extraPackages)
          ]
        );
      in
      pkgs.symlinkJoin {
        name = "carapace-wrapped";
        paths = [ cfg.package ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/carapace ${lib.escapeShellArgs wrapperArgs}
        '';
        inherit (cfg.package) meta;
      };
  bin = lib.getExe finalPackage;
in
{
  meta.maintainers = with lib.maintainers; [
    weathercold
    bobvanderlinden
  ];

  imports = [
    (lib.mkRenamedOptionModule
      [ "programs" "carapace" "ignoreCase" ]
      [ "programs" "carapace" "environment" "match" ]
    )
  ];

  options.programs.carapace = {
    enable = lib.mkEnableOption "carapace, a multi-shell multi-command argument completer";

    package = lib.mkPackageOption pkgs "carapace" { };

    extraPackages = lib.mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = lib.literalExpression ''
        with pkgs; [
          inshellisense
          fish
        ]
      '';
      description = ''
        Extra packages available to Carapace. This can be used to make
        completers listed in {option}`programs.carapace.environment.bridges`
        available.
      '';
    };

    enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration = lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

    environment = lib.mkOption {
      type =
        with lib.types;
        attrsOf (oneOf [
          bool
          int
          str
        ]);
      apply = lib.mapAttrs (
        _name: value: if lib.isBool value then (if value then "1" else "0") else toString value
      );
      default = { };
      example = {
        bridges = "zsh,fish,bash";
        match = true;
      };
      description = ''
        Environment variables for Carapace. The package is wrapped with each
        attribute name uppercased and prefixed by `CARAPACE_`. For example,
        `match = true` sets
        {env}`CARAPACE_MATCH` to `1`.

        See <https://carapace-sh.github.io/carapace-bin/setup/environment.html>
        for the available environment variables.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ finalPackage ];

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
                  buildInputs = [ finalPackage ];
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
