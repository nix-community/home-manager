{
  # Avoid unnecessary downloads in CI jobs and/or make out paths constant, i.e.,
  # not containing hashes, version numbers etc.
  test.stubs = {
    i3 = {
      buildScript = ''
        mkdir -p $out/bin
        echo '#!/bin/sh' > $out/bin/i3
        chmod 755 $out/bin/i3
      '';
    };
  };
}
