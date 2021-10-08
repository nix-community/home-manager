{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.nnn;

  renderSetting = key: value: "${key}:${value}";

  renderSettings = settings:
    concatStringsSep ";" (mapAttrsToList renderSetting settings);

  pluginModule = types.submodule ({ ... }: {
    options = {
      src = mkOption {
        type = with types; nullOr path;
        example = literalExpression ''
          (pkgs.fetchFromGitHub {
            owner = "jarun";
            repo = "nnn";
            rev = "v4.0";
            sha256 = "sha256-Hpc8YaJeAzJoEi7aJ6DntH2VLkoR6ToP6tPYn3llR7k=";
          }) + "/plugins";
        '';
        default = null;
        description = ''
          Path to the plugin folder.
        '';
      };

      mappings = mkOption {
        type = with types; attrsOf str;
        description = ''
          Key mappings to the plugins.
        '';
        default = { };
        example = literalExpression ''
          {
            c = "fzcd";
            f = "finder";
            v = "imgview";
          };
        '';
      };
    };
  });
in {
  meta.maintainers = with maintainers; [ thiagokokada ];

  options = {
    programs.nnn = {
      enable = mkEnableOption "nnn";

      package = mkOption {
        type = types.package;
        default = pkgs.nnn;
        defaultText = literalExpression "pkgs.nnn";
        example =
          literalExpression "pkgs.nnn.override ({ withNerdIcons = true; });";
        description = ''
          Package containing the <command>nnn</command> program.
        '';
      };

      finalPackage = mkOption {
        type = types.package;
        readOnly = true;
        visible = false;
        description = ''
          Resulting nnn package.
        '';
      };

      bookmarks = mkOption {
        type = with types; attrsOf str;
        description = ''
          Directory bookmarks.
        '';
        example = literalExpression ''
          {
            d = "~/Documents";
            D = "~/Downloads";
            p = "~/Pictures";
            v = "~/Videos";
          };
        '';
        default = { };
      };

      extraPackages = mkOption {
        type = with types; listOf package;
        example =
          literalExpression "with pkgs; [ ffmpegthumbnailer mediainfo sxiv ]";
        description = ''
          Extra packages available to nnn.
        '';
        default = [ ];
      };

      plugins = mkOption {
        type = pluginModule;
        description = ''
          Manage nnn plugins.
        '';
        default = { };
      };
    };
  };

  config = let
    nnnPackage = cfg.package.overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ])
        ++ [ pkgs.makeWrapper ];
      postInstall = ''
        ${oldAttrs.postInstall or ""}

        wrapProgram $out/bin/nnn \
          --prefix PATH : "${makeBinPath cfg.extraPackages}" \
          --prefix NNN_BMS : "${renderSettings cfg.bookmarks}" \
          --prefix NNN_PLUG : "${renderSettings cfg.plugins.mappings}"
      '';
    });
  in mkIf cfg.enable {
    programs.nnn.finalPackage = nnnPackage;
    home.packages = [ nnnPackage ];
    xdg.configFile."nnn/plugins" =
      mkIf (cfg.plugins.src != null) { source = cfg.plugins.src; };
  };
}
