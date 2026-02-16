{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf mkOption types;

  cfg = config.programs.pistol;

  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then "Library/Preferences" else config.xdg.configHome;

  configFile = lib.concatStringsSep "\n" (
    map (
      {
        fpath,
        mime,
        command,
      }:
      if fpath == "" then "${mime} ${command}" else "fpath ${fpath} ${command}"
    ) cfg.associations
  );

  association = types.submodule {
    options = {
      command = mkOption {
        type = types.str;
        description = "Preview command for files matched by this association.";
      };

      fpath = mkOption {
        type = types.str;
        default = "";
        description = "File path regex that this association should match.";
      };

      mime = mkOption {
        type = types.str;
        default = "";
        description = "Mime type regex that this association should match.";
      };
    };
  };
in
{
  meta.maintainers = [ lib.maintainers.mtoohey ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "pistol"
      "config"
    ] "Pistol is now configured with programs.pistol.associations.")
  ];
  options.programs.pistol = {
    enable = lib.mkEnableOption "file previewer for terminal file managers";

    package = lib.mkPackageOption pkgs "pistol" { nullable = true; };

    associations = mkOption {
      type = types.listOf association;
      default = [ ];
      example = lib.literalExpression ''
        [
          { mime = "application/json"; command = "bat %pistol-filename%"; }
          { mime = "application/*"; command = "hexyl %pistol-filename%"; }
          { fpath = ".*.md$"; command = "sh: bat --paging=never --color=always %pistol-filename% | head -8"; }
        ]
      '';
      description = ''
        Associations written to the Pistol configuration at
        {file}`$XDG_CONFIG_HOME/pistol/pistol.conf`.
      '';
    };

  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.all (
          { fpath, mime, ... }: (fpath != "" && mime == "") || (fpath == "" && mime != "")
        ) cfg.associations;
        message = ''
          Each entry in programs.pistol.associations must contain exactly one
          of fpath or mime.
        '';
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/pistol/pistol.conf" = mkIf (cfg.associations != [ ]) {
      text = configFile;
    };
  };
}
