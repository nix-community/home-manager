{ config, lib, pkgs, ... }:

{
  programs.gpg = {
    enable = true;

    mutableKeys = false;
    mutableTrust = false;

    publicKeys = [
      {
        source = pkgs.fetchurl {
          url =
            "https://keys.openpgp.org/pks/lookup?op=get&options=mr&search=0x36cacf52d098cc0e78fb0cb13573356c25c424d4";
          hash = "sha256-9Zjsb/TtOyiPzMO/Jg3CtJwSxuw7QmX0pcfZT2/1w5E=";
        };
        trust = 1; # "unknown"
      }
      {
        source = pkgs.fetchurl {
          url = "https://www.rsync.net/resources/pubkey.txt";
          sha256 = "16nzqfb1kvsxjkq919hxsawx6ydvip3md3qyhdmw54qx6drnxckl";
        };
        trust = "never";
      }
    ];
  };

  nmt.script = ''
    assertFileNotRegex activate "^export GNUPGHOME='/home/hm-user/.gnupg'$"

    assertFileRegex activate \
      '^install -m 0700 /nix/store/[0-9a-z]*-gpg-pubring/trustdb.gpg "/home/hm-user/.gnupg/trustdb.gpg"$'

    # Setup GPGHOME
    export GNUPGHOME=$(mktemp -d)
    cp -r $TESTED/home-files/.gnupg/* $GNUPGHOME
    TRUSTDB=$(grep -o '/nix/store/[0-9a-z]*-gpg-pubring/trustdb.gpg' $TESTED/activate)
    install -m 0700 $TRUSTDB $GNUPGHOME/trustdb.gpg

    # Export Trust
    export WORKDIR=$(mktemp -d)
    ${pkgs.gnupg}/bin/gpg -q --export-ownertrust > $WORKDIR/gpgtrust.txt

    # Check Trust
    assertFileRegex $WORKDIR/gpgtrust.txt \
      '^36CACF52D098CC0E78FB0CB13573356C25C424D4:2:$'

    assertFileRegex $WORKDIR/gpgtrust.txt \
      '^BB847B5A69EF343CEF511B29073C282D7D6F806C:3:$'
  '';
}
