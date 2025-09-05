{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkIf
    mkOption
    mkChangedOptionModule
    mkRenamedOptionModule
    types
    ;

  cfg = config.programs.go;
  keyValueFormat = pkgs.formats.keyValue { };

  modeFileContent = "${cfg.telemetry.mode} ${cfg.telemetry.date}";
in
{
  meta.maintainers = [ lib.maintainers.rvolosatovs ];

  imports = [
    (mkChangedOptionModule [ "programs" "go" "goPath" ] [ "programs" "go" "env" "GOPATH" ] (config: [
      "${config.home.homeDirectory}/${config.programs.go.goPath}"
    ]))

    (mkChangedOptionModule [ "programs" "go" "extraGoPaths" ] [ "programs" "go" "env" "GOPATH" ] (
      config:
      lib.mkOrder 1500 (map (x: "${config.home.homeDirectory}/${x}") config.programs.go.extraGoPaths)
    ))

    (mkChangedOptionModule [ "programs" "go" "goBin" ] [ "programs" "go" "env" "GOBIN" ] (
      config: "${config.home.homeDirectory}/${config.programs.go.goBin}"
    ))

    (mkRenamedOptionModule [ "programs" "go" "goPrivate" ] [ "programs" "go" "env" "GOPRIVATE" ])
  ];

  options = {
    programs.go = {
      enable = lib.mkEnableOption "Go";

      package = lib.mkPackageOption pkgs "go" { nullable = true; };

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

      env = mkOption {
        type = types.submodule {
          freeformType = with types; attrsOf str;
          options = {
            GOPATH = mkOption {
              type = with types; either str (listOf str);
              apply = x: lib.concatStringsSep ":" (lib.toList x);
              default = "";
              description = "List of directories that should be used by the Go tooling.";
            };
            GOPRIVATE = mkOption {
              type = with types; either str (listOf str);
              apply = x: lib.concatStringsSep "," (lib.toList x);
              default = "";
              description = ''
                Controls which modules the 'go' command considers to be private (not
                available publicly) and should therefore not use the proxy or checksum database.
              '';
            };
          };
        };
        default = { };
        example = lib.literalExpression ''
          {
            GOPATH = [
              "''${config.home.homeDirectory}/mygo"
              "/another/go"
              "/yet/another/go"
            ];

            GOPRIVATE = [
              "*.corp.example.com"
              "rsc.io/private"
            ];

            CXX = "g++";
            GCCGO = "gccgo";
            GOAMD64 = "v1";
            GOARCH = "amd64";
            GOAUTH = "netrc";
          };
        '';
        description = ''
          Environment variables for Go. All the available options
          can be found running 'go env'.
        '';
      };

      telemetry = mkOption {
        type = types.submodule {
          options = {
            mode = mkOption {
              type =
                with types;
                nullOr (enum [
                  "off"
                  "local"
                  "on"
                ]);
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

  config =
    let
      firstGoPath = lib.elemAt (lib.splitString ":" cfg.env.GOPATH) 0;
      finalEnv = lib.filterAttrs (_: v: v != "") cfg.env;
    in
    mkIf cfg.enable (
      lib.mkMerge [
        {
          assertions = [
            {
              assertion =
                cfg.packages != { } -> cfg.env.GOPATH != "" -> lib.hasPrefix config.home.homeDirectory firstGoPath;
              message = "The first element of `programs.go.env.GOPATH must be an absolute path that points to a directory inside ${config.home.homeDirectory} if `programs.go.packages` is set.";
            }
          ];
          home.packages = mkIf (cfg.package != null) [ cfg.package ];

          home.file = mkIf (cfg.packages != { }) (
            let
              mainGoPath = if (cfg.env.GOPATH != "") then firstGoPath else "go";

              mkSrc = n: v: { "${mainGoPath}/src/${n}".source = v; };
            in
            lib.foldl' (a: b: a // b) { } (lib.mapAttrsToList mkSrc cfg.packages)
          );
        }

        (mkIf (cfg.env != { }) {
          xdg.configFile."go/env" = {
            enable = !pkgs.stdenv.hostPlatform.isDarwin;
            source = keyValueFormat.generate "go-env" finalEnv;
          };

          home.file."Library/Application Support/go/env" = {
            enable = pkgs.stdenv.hostPlatform.isDarwin;
            source = keyValueFormat.generate "go-env" finalEnv;
          };
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
      ]
    );
}
