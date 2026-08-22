{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xonsh;
  inherit (lib) types mkOption;
in
{
  options.programs.xonsh = {
    enable = lib.mkEnableOption "xonsh";

    package = lib.mkPackageOption pkgs "xonsh" { };
    finalPackage = lib.mkOption {
      type = types.package;
      internal = true;
      description = "Package that will actually get installed";
    };
    config = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra text added to the end of `/etc/xonsh/xonshrc`,
        the system-wide control file for xonsh.
      '';
    };
    shellAliases = mkOption {
      type = with types; attrsOf (either str (listOf str));
      default = { };
      example = {
        ll = [
          "ls"
          "-l"
        ];
        la = "ls -a";
      };
      description = ''
        An attribute set that maps aliases (the top level attribute names in
        this option) to commands
      '';
    };
    extraPackages = lib.mkOption {
      default = (ps: [ ]);
      defaultText = lib.literalExpression "ps: [ ]";
      example = lib.literalExpression ''
        ps: with ps; [ numpy xonsh.xontribs.xontrib-vox ]
      '';
      type =
        with lib.types;
        coercedTo (listOf lib.types.package) (v: (_: v)) (functionTo (listOf lib.types.package));
      description = ''
        Xontribs and extra Python packages to be available in xonsh.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.xonsh = {
      config = lib.mkMerge (
        lib.mapAttrsToList (n: v: "aliases['${n}']=${builtins.toJSON v}") cfg.shellAliases
      );
      shellAliases = lib.mapAttrs (n: lib.mkDefault) config.home.shellAliases;
      finalPackage = (
        cfg.package.override (old: {
          inherit (cfg) extraPackages;
        })
      );
    };
    xdg.configFile."xonsh/rc.xsh" = {
      enable = cfg.config != "";
      text = cfg.config;
    };
  };
}
