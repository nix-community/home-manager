{
  test.stubs.kakoune-unwrapped = {
    name = "dummy-kakoune";
    version = "1";
    outPath = null;
    buildScript = ''
      mkdir -p $out/bin $out/share/kak/doc
      touch $out/bin/kak
      chmod +x $out/bin/kak
    '';
  };
}
