{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.go;

  modeFileContent = "${cfg.telemetry.mode} ${cfg.telemetry.date}";

in {
  meta.maintainers = [ maintainers.rvolosatovs ];

  options = {
    programs.go = {
      enable = mkEnableOption "Go";

      package = mkOption {
        type = types.package;
        default = pkgs.go;
        defaultText = literalExpression "pkgs.go";
        description = "The Go package to use.";
      };

      packages = mkOption {
        type = with types; attrsOf path;
        default = { };
        example = literalExpression ''
          {
            "golang.org/x/text" = builtins.fetchGit "https://go.googlesource.com/text";
            "golang.org/x/time" = builtins.fetchGit "https://go.googlesource.com/time";
          }
        '';
        description = "Packages to add to GOPATH.";
      };

      goPath = mkOption {
        type = with types; nullOr str;
        default = null;
        example = "go";
        description = ''
          Primary {env}`GOPATH` relative to
          {env}`HOME`. It will be exported first and therefore
          used by default by the Go tooling.
        '';
      };

      extraGoPaths = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "extraGoPath1" "extraGoPath2" ];
        description = ''
          Extra {env}`GOPATH`s relative to {env}`HOME` appended
          after [](#opt-programs.go.goPath), if that option is set.
        '';
      };

      goBin = mkOption {
        type = with types; nullOr str;
        default = null;
        example = ".local/bin.go";
        description = "GOBIN relative to HOME";
      };

      goPrivate = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "*.corp.example.com" "rsc.io/private" ];
        description = ''
          The {env}`GOPRIVATE` environment variable controls
          which modules the go command considers to be private (not
          available publicly) and should therefore not use the proxy
          or checksum database.
        '';
      };

      telemetry = mkOption {
        type = types.submodule {
          options = {
            mode = mkOption {
              type = with types; nullOr (enum [ "off" "local" "on" ]);
              default = null;
              description = "Go telemetry mode to be set.";
            };

            date = mkOption {
              type = types.str;
              default = "1970-01-01";
              description = ''
                The date indicating the date at which the modefile
                was updated, in YYYY-MM-DD format. It's used to
                reset the timeout before the next telemetry report
                is uploaded when telemetry mode is set to "on".
              '';
            };
          };
        };
        default = { };
        description = "Options to configure Go telemetry mode.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.package ];

      home.file = let
        goPath = if cfg.goPath != null then cfg.goPath else "go";
        mkSrc = n: v: { "${goPath}/src/${n}".source = v; };
      in foldl' (a: b: a // b) { } (mapAttrsToList mkSrc cfg.packages);
    }

    (mkIf (cfg.goPath != null) {
      home.sessionVariables.GOPATH = concatStringsSep ":" (map builtins.toPath
        (map (path: "${config.home.homeDirectory}/${path}")
          ([ cfg.goPath ] ++ cfg.extraGoPaths)));
    })

    (mkIf (cfg.goBin != null) {
      home.sessionVariables.GOBIN =
        builtins.toPath "${config.home.homeDirectory}/${cfg.goBin}";
    })

    (mkIf (cfg.goPrivate != [ ]) {
      home.sessionVariables.GOPRIVATE = concatStringsSep "," cfg.goPrivate;
    })

    (mkIf (cfg.telemetry.mode != null) {
      home.file."Library/Application Support/go/telemetry/mode" = {
        enable = pkgs.stdenv.hostPlatform.isDarwin;
        text = modeFileContent;
      };

      xdg.configFile."go/telemetry/mode" = {
        enable = !pkgs.stdenv.hostPlatform.isDarwin;
        text = modeFileContent;
      };
    })
  ]);
}
