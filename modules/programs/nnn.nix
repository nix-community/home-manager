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
          Package containing the {command}`nnn` program.
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

      enableBashIntegration = mkEnableOption "Bash integration" // {
        default = true;
      };

      enableZshIntegration = mkEnableOption "Zsh integration" // {
        default = true;
      };

      enableFishIntegration = mkEnableOption "Fish integration" // {
        default = true;
      };

      quitcd = mkEnableOption "cd on quit" // { default = false; };
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

    quitcd = {
      bash_sh_zsh =
        builtins.readFile "${nnnPackage}/share/quitcd/quitcd.bash_sh_zsh";
      fish = builtins.readFile "${nnnPackage}/share/quitcd/quitcd.fish";
    };
  in mkIf cfg.enable {
    programs.nnn.finalPackage = nnnPackage;
    home.packages = [ nnnPackage ];
    xdg.configFile."nnn/plugins" =
      mkIf (cfg.plugins.src != null) { source = cfg.plugins.src; };

    programs.bash.initExtra = mkIf (cfg.enableBashIntegration && cfg.quitcd)
      (mkAfter quitcd.bash_sh_zsh);
    programs.zsh.initExtra = mkIf (cfg.enableZshIntegration && cfg.quitcd)
      (mkAfter quitcd.bash_sh_zsh);
    programs.fish.interactiveShellInit =
      mkIf (cfg.enableFishIntegration && cfg.quitcd) (mkAfter quitcd.fish);
  };
}
