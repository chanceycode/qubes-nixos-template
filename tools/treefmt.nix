{ ... }:
{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "LICENSE"
    "*.md"
  ];
  programs = {
    deadnix.enable = true;
    nixfmt.enable = true;
  };
}
