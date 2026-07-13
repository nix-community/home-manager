{
  lib,
  config,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      ignoreUserConfig = true;
      sessionVariables = {
        NIXOS_OZONE_WL = 1;
        XMODIFIERS = "@im=fcitx";
      };
    };
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'GLFW_IM_MODULE'
    assertFileNotRegex home-path/etc/profile.d/hm-session-vars.sh 'SDL_IM_MODULE'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export SKIP_FCITX_USER_PATH="1"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export NIXOS_OZONE_WL="1"'
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh 'export XMODIFIERS="@im=fcitx"'
  '';
}
