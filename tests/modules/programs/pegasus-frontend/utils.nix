lib: {
  # small helper function to assert a meta file's contents
  # allows input as string (written to file) or file
  assertMetaFile = name: expected: ''
    assertFileExists /nix/store/*-pegasus-metadata/${name}
    assertFileContent $(normalizeStorePaths /nix/store/*-pegasus-metadata/${name}) ${
      if builtins.isString expected then (builtins.toFile "expected.txt" expected) else expected
    }
  '';
  # converts a name to the hashed metadata.pegasus.txt the module writes
  metaName = name: "${lib.substring 0 32 (builtins.hashString "sha256" name)}.metadata.pegasus.txt";
}
