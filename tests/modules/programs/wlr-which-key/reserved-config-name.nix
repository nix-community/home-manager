{
  programs.wlr-which-key = {
    enable = true;
    extraMenus.config.menu = [
      {
        key = "a";
        desc = "test";
        cmd = "true";
      }
    ];
  };

  test.asserts.assertions.expected = [
    ''
      programs.wlr-which-key.extraMenus."config" is reserved because it
      collides with the main settings target (wlr-which-key/config.yaml).
      Choose a different name for this menu.
    ''
  ];
}
