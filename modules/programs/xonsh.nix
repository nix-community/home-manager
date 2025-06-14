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
    xonshrc = mkOption {
      type = types.lines;
      default = "";
      description = ''
        The contents of .xonshrc
      '';
    };
    pythonPackages = mkOption {
      type = types.raw;
      default = pkgs.pythonPackages;
      defaultText = "pkgs.pythonPackages";
      description = ''
        The pythonPackages set extraPackages are taken from
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
      type =
        with lib.types;
        coercedTo (listOf lib.types.package) (v: (_: v)) (functionTo (listOf lib.types.package));
      description = ''
        Add the specified extra packages to the xonsh package.
        Preferred over using `programs.xonsh.package` as it composes with `pkgs.xonsh.xontribs`.
        Take care in using this option along with manually defining the package
        option above, as the two can result in conflicting sets of build dependencies.
        This option assumes that the package option has an overridable argument
        called `extraPackages`, so if you override the package option but also
        intend to use this option as in the case of many enableXonshIntegration options,
        be sure that your resulting package still honors the necessary option.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.finalPackage ];
    programs.xonsh = {
      xonshrc = lib.mkMerge (
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
      enable = cfg.xonshrc != "";
      text = cfg.xonshrc;
    };
  };
}
