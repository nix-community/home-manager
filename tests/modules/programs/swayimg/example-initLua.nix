{ config, ... }:

{
  programs.swayimg = {
    enable = true;
    package = config.lib.test.mkStubPackage { };

    initLua = ''
      swayimg.text.set_size(32)
      swayimg.text.set_foreground(0xffff0000)

      swayimg.viewer.set_default_scale("fill")

      swayimg.gallery.on_key("Delete", function()
        local image = swayimg.gallery.get_image()
        os.remove(image.path)
      end)
    '';
  };

  nmt.script = ''
    assertFileContent \
      home-files/.config/swayimg/init.lua \
      ${./example-initLua-expected.lua}
  '';
}
