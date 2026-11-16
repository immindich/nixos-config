{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    claude-desktop = {
      url = "github:danielbodart/claude-desktop";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emacs-overlay = {
      url = "github:nix-community/emacs-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
};

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      username = "isaiah";
      system = "x86_64-linux";

      # Each host is hosts/<name>/configuration.nix plus the modules every
      # machine shares. Machine-specific modules (battery, fingerprint) are
      # imported from the host's own configuration.nix.
      mkHost = hostname: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}/configuration.nix
          ./modules/common.nix
          ./modules/claude-desktop.nix
          ./modules/vm.nix
          ./modules/emacs.nix
          home-manager.nixosModules.home-manager {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit inputs; };
            home-manager.users.${username} = import ./home/common.nix;
          }
        ];
      };
    in {
      nixosConfigurations.laptop = mkHost "laptop";

      homeConfigurations."${username}@laptop" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home/common.nix ];
        };
    };
}
