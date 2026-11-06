{
  time = "2026-10-30T17:40:19+00:00";
  condition = true;
  message = ''
    A new module is available: 'agents.skills'.

    It installs agent skills into '~/.agents/skills', the shared skills
    directory read by several AI coding agents. Skills can come from
    packages following the nixpkgs 'installAgentSkills' convention
    ('agents.skills.packages'), directories of skills
    ('agents.skills.bundles'), or individually named skills
    ('agents.skills.skills'). Skills are linked individually, so the
    directory remains writable for skills managed outside of Home Manager.
  '';
}
