{ ... }: {
  services.cliphist = {
    enable = true;
    allowImages = true;
    extraOptions = [ "-max-dedupe-search" "10" "-max-items" "500" ];
  };

  test.stubs = {
    cliphist = { };
    wl-clipboard = { };
  };

  nmt.script = ''
    servicePath=home-files/.config/systemd/user

    assertFileExists $servicePath/cliphist.service
    assertFileExists $servicePath/cliphist-images.service

    assertFileRegex $servicePath/cliphist.service " -max-dedupe-search 10 "
    assertFileRegex $servicePath/cliphist.service " -max-items 500 "
    assertFileRegex $servicePath/cliphist-images.service " -max-dedupe-search 10 "
    assertFileRegex $servicePath/cliphist-images.service " -max-items 500 "
  '';
}
