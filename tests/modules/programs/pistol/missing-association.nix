{
  programs.pistol = {
    enable = true;
    # contains no fpath or mime value
    associations = [{ command = "bat %pistol-filename%"; }];
  };

  test.stubs.pistol = { };

  test.asserts.assertions.expected = [''
    Each entry in programs.pistol.associations must contain exactly one
    of fpath or mime.
  ''];
}
