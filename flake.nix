{
  description = "nixos templatevm configurations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
      systems,
      ...
    }:
    let
      lib = nixpkgs.lib;
      system = "x86_64-linux";
      qubesPackages = _final: prev: {
        qubes-core-qubesdb = prev.callPackage ./pkgs/qubes-core-qubesdb { };
        qubes-core-vchan-xen = prev.callPackage ./pkgs/qubes-core-vchan-xen { };
        qubes-core-qrexec = prev.callPackage ./pkgs/qubes-core-qrexec { };
        qubes-core-agent-linux = prev.callPackage ./pkgs/qubes-core-agent-linux { };
        qubes-linux-utils = prev.callPackage ./pkgs/qubes-linux-utils { };
        qubes-gui-common = prev.callPackage ./pkgs/qubes-gui-common { };
        qubes-gui-agent-linux = prev.callPackage ./pkgs/qubes-gui-agent-linux { };
        qubes-sshd = prev.callPackage ./pkgs/qubes-sshd { };
        qubes-usb-proxy = prev.callPackage ./pkgs/qubes-usb-proxy { };
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          qubesPackages
        ];
      };

      # TODO: Clean this up.
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./tools/treefmt.nix);
    in
    {
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });

      overlays.default = qubesPackages;
      nixosModules.default =
        {
          ...
        }:
        {
          imports = [
            ./modules/qubes/core.nix
            ./modules/qubes/db.nix
            ./modules/qubes/gui.nix
            ./modules/qubes/networking.nix
            ./modules/qubes/qrexec.nix
            ./modules/qubes/sshd.nix
            ./modules/qubes/updates.nix
            ./modules/qubes/usb.nix
          ];
        };
      nixosProfiles.default =
        {
          ...
        }:
        {
          imports = [
            ./profiles/qubes.nix
          ];
        };
      rpm = pkgs.callPackage ./tools/rpm.nix {
        inherit nixpkgs;
        qubesVersion = "4.2.0";
        nixosConfig = lib.nixosSystem {
          inherit pkgs system;
          modules = [
            self.nixosModules.default
            self.nixosProfiles.default
            ./examples/configuration.nix
          ];
        };
      };
    };
}
