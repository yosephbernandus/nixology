{
  description = "Development services environment";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells = {
          # Main development shell with all services
          devs = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "all";
          };

          # Individual service shells
          postgres = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "postgres";
          };

          redis = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "redis";
          };

          rabbitmq = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "rabbitmq";
          };

          # Combined services
          database = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "postgres redis";
          };

          # Make devs the default
          default = self.devShells.${system}.devs;
        };
      }
    );
}
