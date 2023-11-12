{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.pistol;

  configFile = concatStringsSep "\n" (map ({ fpath, mime, command }:
    if fpath == "" then "${mime} ${command}" else "fpath ${fpath} ${command}")
    cfg.associations);

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
in {
  imports = [
    (mkRemovedOptionModule [ "programs" "pistol" "config" ]
      "Pistol is now configured with programs.pistol.associations.")
  ];

  meta.maintainers = [ hm.maintainers.mtoohey ];

  options.programs.pistol = {
    enable = mkEnableOption "file previewer for terminal file managers";

    associations = mkOption {
      type = types.listOf association;
      default = [ ];
      example = literalExpression ''
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

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [{
        assertion = all ({ fpath, mime, ... }:
          (fpath != "" && mime == "") || (fpath == "" && mime != ""))
          cfg.associations;
        message = ''
          Each entry in programs.pistol.associations must contain exactly one
          of fpath or mime.
        '';
      }];

      home.packages = [ pkgs.pistol ];
    }

    (mkIf (cfg.associations != [ ] && pkgs.stdenv.hostPlatform.isDarwin) {
      home.file."Library/Application Support/pistol/pistol.conf".text =
        configFile;
    })

    (mkIf (cfg.associations != [ ] && !pkgs.stdenv.hostPlatform.isDarwin) {
      xdg.configFile."pistol/pistol.conf".text = configFile;
    })
  ]);
}
