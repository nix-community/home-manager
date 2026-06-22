{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  cfg = config.programs.nnn;

  renderSetting = key: value: "${key}:${value}";

  renderSettings = settings: lib.concatStringsSep ";" (lib.mapAttrsToList renderSetting settings);

  pluginModule = types.submodule {
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
  };
in
{
  meta.maintainers = [ ];

  options = {
    programs.nnn = {
      enable = lib.mkEnableOption "nnn";

      package = lib.mkPackageOption pkgs "nnn" {
        example = "pkgs.nnn.override { withNerdIcons = true; }";
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
        example = literalExpression "with pkgs; [ ffmpegthumbnailer mediainfo sxiv ]";
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

      options = mkOption {
        type =
          with lib.types;
          let
            scalar = oneOf [
              bool
              int
              str
            ];
            attrs = attrsOf scalar;
          in
          coercedTo attrs (lib.cli.toCommandLineGNU { }) (listOf str);
        default = { };
        example = {
          s = "session_name";
          t = 8;
          A = true;
        };
        description = "Configuration options for {command}`nnn`. See {command}`nnn -h`";
      };

      enableBashIntegration = lib.hm.shell.mkBashIntegrationOption { inherit config; };

      enableFishIntegration = lib.hm.shell.mkFishIntegrationOption { inherit config; };

      enableZshIntegration = lib.hm.shell.mkZshIntegrationOption { inherit config; };

      quitcd = lib.mkEnableOption "cd on quit";
    };
  };

  config =
    let
      nnnPackage = cfg.package.overrideAttrs (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [ pkgs.makeWrapper ];
        postInstall =
          let
            args = lib.concatMap (arg: [
              "--add-flags"
              arg
            ]) cfg.options;
          in
          ''
            ${oldAttrs.postInstall or ""}

            wrapProgram $out/bin/nnn \
              --prefix PATH : "${lib.makeBinPath cfg.extraPackages}" \
              --prefix NNN_BMS : "${renderSettings cfg.bookmarks}" \
              --prefix NNN_PLUG : "${renderSettings cfg.plugins.mappings}" \
              ${lib.concatStringsSep " " args}
          '';
      });

      quitcd = {
        bash_sh_zsh = "source ${nnnPackage}/share/quitcd/quitcd.bash_sh_zsh";
        fish = "source ${nnnPackage}/share/quitcd/quitcd.fish";
      };
    in
    lib.mkIf cfg.enable {
      programs.nnn.finalPackage = nnnPackage;
      home.packages = [ nnnPackage ];
      xdg.configFile."nnn/plugins" = lib.mkIf (cfg.plugins.src != null) { source = cfg.plugins.src; };

      programs.bash.initExtra = lib.mkIf (cfg.enableBashIntegration && cfg.quitcd) (
        lib.mkAfter quitcd.bash_sh_zsh
      );
      programs.fish.interactiveShellInit = lib.mkIf (cfg.enableFishIntegration && cfg.quitcd) (
        lib.mkAfter quitcd.fish
      );
      programs.zsh.initContent = lib.mkIf (cfg.enableZshIntegration && cfg.quitcd) (
        lib.mkAfter quitcd.bash_sh_zsh
      );
    };
}
