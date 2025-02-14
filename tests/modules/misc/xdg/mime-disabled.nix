{ ... }: {
  config = {
    xdg.mime.enable = false;
    nmt.script = ''
      # assert that neither application is run
      assertPathNotExists home-path/share/applications/mimeinfo.cache
      assertPathNotExists home-path/share/applications/mime
    '';
  };
}
