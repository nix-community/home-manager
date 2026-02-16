{ realPkgs, ... }:

{
  programs.gpg = {
    enable = true;
    package = realPkgs.gnupg;

    mutableKeys = false;
    mutableTrust = false;

    publicKeys = [
      {
        # This file contains three public keys
        # The bug causes only the first key to have trust set
        source = ./test-keys/multiple-keys.asc;
        trust = "ultimate"; # trust level 5
      }
    ];
  };

  nmt.script = ''
    assertFileNotRegex activate "^export GNUPGHOME=/home/hm-user/.gnupg$"

    assertFileRegex activate \
      '^install -m 0700 /nix/store/[0-9a-z]*-gpg-pubring/trustdb.gpg "/home/hm-user/.gnupg/trustdb.gpg"$'

    # Setup GPGHOME
    export GNUPGHOME=$(mktemp -d)
    cp -r $TESTED/home-files/.gnupg/* $GNUPGHOME
    TRUSTDB=$(grep -o '/nix/store/[0-9a-z]*-gpg-pubring/trustdb.gpg' $TESTED/activate)
    install -m 0700 $TRUSTDB $GNUPGHOME/trustdb.gpg

    # Export Trust
    export WORKDIR=$(mktemp -d)
    ${realPkgs.gnupg}/bin/gpg -q --export-ownertrust > $WORKDIR/gpgtrust.txt

    echo "=== Trust database contents ==="
    cat $WORKDIR/gpgtrust.txt
    echo "=== End of trust database ==="

    # The test file contains three keys:
    # - 13B06D9193E01E0F (Test User One) - fingerprint: B07502E7B7ED0A4AA3BF191913B06D9193E01E0F
    # - 42E7B990011430DE (Test User Two) - fingerprint: 6A2A713AE7F93C8EA6D264B642E7B990011430DE
    # - DFC825F8209CE742 (Test User Three) - fingerprint: E66D263DC7174345AB102829DFC825F8209CE742
    #
    # All three keys should have ultimate trust (level 6 in ownertrust format)
    # Due to the bug in importTrust function, only the first key gets trust set

    # Check that first key has ultimate trust (this works with current code)
    assertFileRegex $WORKDIR/gpgtrust.txt \
      '^B07502E7B7ED0A4AA3BF191913B06D9193E01E0F:6:$'

    # Check that second key has ultimate trust (this FAILS due to bug)
    assertFileRegex $WORKDIR/gpgtrust.txt \
      '^6A2A713AE7F93C8EA6D264B642E7B990011430DE:6:$'

    # Check that third key has ultimate trust (this FAILS due to bug)
    assertFileRegex $WORKDIR/gpgtrust.txt \
      '^E66D263DC7174345AB102829DFC825F8209CE742:6:$'
  '';
}
