{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    claude-desktop = {
      url = "github:danielbodart/claude-desktop";
      inputs.nixpkgs.follows = "nixpkgs";
    };
};

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      hostname = "laptop";
      username = "isaiah";
      system = "x86_64-linux";
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
	  ./hosts/laptop/configuration.nix
	  ./modules/common.nix
	  ./modules/claude-desktop.nix
          home-manager.nixosModules.home-manager {
	    home-manager.useGlobalPkgs = true;
	    home-manager.useUserPackages = true;
	    home-manager.backupFileExtension = "backup";
	    home-manager.extraSpecialArgs = { inherit inputs; };
	    home-manager.users.${username} = import ./home/common.nix;
	  }
	];
      };

      homeConfigurations."${username}@${hostname}" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home/common.nix ];
        };
    };
}
