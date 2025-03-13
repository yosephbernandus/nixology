{
  description = "Development services environment";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs-python.url = "github:cachix/nixpkgs-python";
  };

  outputs = { self, nixpkgs, flake-utils, nixpkgs-python }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # pkgs = nixpkgs.legacyPackages.${system}.extend (final: prev: {
        #   config.allowUnfree = true;
        # });
        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
          };
        };

        python37 = nixpkgs-python.packages.${system}."3.7";
      in
      {
        devShells = {
          # Main development shell with all services
          devs = import ./shells/dev { 
            inherit pkgs; 
            enabledServices = "all";
          };

          # Terraform shell
          terraform = import ./shells/terraform { inherit pkgs; };

          # Python 3.7 shell
          python37 = import ./shells/python37 { 
            inherit pkgs python37; 
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
