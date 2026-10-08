{
  config = {
    test.asserts.warnings.expected = [
      "programs.man.man-db.extraConfig has no effect when programs.man.generateCaches is false"
    ];

    programs.man = {
      enable = true;
      generateCaches = false;
      man-db.extraConfig = ''
        MANDATORY_MANPATH /usr/man
        SECTION 1 n l 8
      '';
    };
  };
}
