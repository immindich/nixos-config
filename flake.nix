{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
};

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:
    let
      hostname = "laptop";
      username = "isaiah";
      system = "x86_64-linux";
    in {
      nixosConfigurations.${hostname} = nixpkgs.lib.nixosSystem {
        modules = [ ./hosts/laptop/configuration.nix ./modules/common.nix ];
      };

      homeConfigurations."${username}@${hostname}" =
        home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${system};
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./home/common.nix ];
        };
    };
}
