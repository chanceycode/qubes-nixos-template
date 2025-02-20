{ ... }:
{
  projectRootFile = "flake.nix";
  settings.global.excludes = [
    "LICENSE"
    "*.md"
  ];
  programs.nixfmt.enable = true;
}
