{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.swayimg;
in
{
  meta.maintainers = with lib.maintainers; [ dod-101 ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "swayimg"
      "settings"
    ] "Upstream moved to a lua config. This option has been replaced by programs.swayimg.initLua.")
  ];

  options.programs.swayimg = {
    enable = lib.mkEnableOption "swayimg";

    package = lib.mkPackageOption pkgs "swayimg" { };

    initLua = lib.mkOption {
      type = with lib.types; nullOr (either path lines);
      default = null;
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/swayimg/init.lua`.

        See <https://github.com/artemsen/swayimg/blob/master/CONFIG.md>
        for documentation.
      '';
      example = lib.literalExpression ''
        swayimg.text.set_size(32)
        swayimg.text.set_foreground(0xffff0000)

        swayimg.viewer.set_default_scale("fill")

        swayimg.gallery.on_key("Delete", function()
          local image = swayimg.gallery.get_image()
          os.remove(image.path)
        end)
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.swayimg" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    xdg.configFile."swayimg/init.lua" = lib.mkIf (cfg.initLua != null) {
      text = if builtins.isPath cfg.initLua then builtins.readFile cfg.initLua else cfg.initLua;
    };
  };
}
