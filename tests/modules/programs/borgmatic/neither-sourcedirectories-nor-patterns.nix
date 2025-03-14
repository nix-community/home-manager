{
  programs.borgmatic = {
    enable = true;
    backups = { main = { location = { repositories = [ "/mnt/disk1" ]; }; }; };
  };

  test.asserts.assertions.expected = [''
    Borgmatic backup configuration "main" must specify one of 'location.sourceDirectories' or 'location.patterns'.
  ''];
}
