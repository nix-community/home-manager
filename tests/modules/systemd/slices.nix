{ ... }:

{
  systemd.user.slices.app-test = {
    Unit = { Description = "Slice for a test app"; };

    Slice = {
      MemoryHigh = "30%";
      MemoryMax = "40%";
    };
  };

  nmt.script = ''
    sliceFile=home-files/.config/systemd/user/app-test.slice
    assertFileExists $sliceFile
    assertFileContent $sliceFile ${
      builtins.toFile "app-test-expected.conf" ''
        [Slice]
        MemoryHigh=30%
        MemoryMax=40%

        [Unit]
        Description=Slice for a test app
      ''
    }
  '';
}
