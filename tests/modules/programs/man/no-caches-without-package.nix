{
  config = {
    home.stateVersion = "26.05";

    programs.man = {
      enable = true;
      package = null;
      cache.enable = true;
    };

    test.asserts.warnings.expected = [
      "programs.man.cache.enable has no effect when programs.man.package is null"
    ];

    nmt.script = ''
      assertPathNotExists home-files/.manpath
    '';
  };
}
