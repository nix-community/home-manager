{
  programs.cargo = {
    enable = true;

    enableSccache = true;
  };

  nmt.script =
    let
      configTestPath = "home-files/.cargo/config.toml";
    in
    ''
      assertPathNotExists home-files/.cargo/config
      assertFileExists ${configTestPath}
      assertFileRegex ${configTestPath} '\[build\]'
      assertFileRegex ${configTestPath} 'rustc_wrapper = "/nix/store/.*-sccache-.*/bin/sccache"'
    '';
}
