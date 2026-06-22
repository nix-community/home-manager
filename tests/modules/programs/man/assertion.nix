{
  config = {
    test.asserts.assertions.expected = [
      ''
        man-db and mandoc can't be used as the man page viewer at the same time!
      ''
    ];

    programs.man = {
      enable = true;
      man-db.enable = true;
      mandoc.enable = true;
    };
  };
}
