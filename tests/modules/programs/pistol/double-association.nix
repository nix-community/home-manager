{
  programs.pistol = {
    enable = true;
    # contains both fpath and mime
    associations = [{
      fpath = ".*.md$";
      mime = "application/json";
      command = "bat %pistol-filename%";
    }];
  };

  test.stubs.pistol = { };

  test.asserts.assertions.expected = [''
    Each entry in programs.pistol.associations must contain exactly one
    of fpath or mime.
  ''];
}
