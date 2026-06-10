# Release Notes {#sec-contributing-release-notes}

Home Manager release notes are published as part of the website documentation in
`docs/release-notes/rl-*.md`. They are intended for users migrating from one
stable release to another.

A change should be mentioned in the release notes when it affects migration
between stable releases. This includes changes that require user action or
awareness during an upgrade, such as:

- breaking changes;
- default changes guarded by `home.stateVersion`;
- required migration steps;
- broad behavior changes across platform or integration boundaries;
- compatibility changes that can affect existing configurations.

Do not use the presence or absence of a news entry to decide whether a change
belongs in the release notes. A change can require a news entry, a release note,
both, or neither.

When preparing a release, review the commits since the previous stable release
and update the upcoming release note file with the migration impact. Prefer
concise user-facing descriptions that name the affected option paths and explain
required action.
