{
  config = {
    programs.man = {
      enable = false;
      man-db.enable = true;
      mandoc.enable = false;
      generateCaches = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.manpath
    '';
  };
}
