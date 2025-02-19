{
  description = "Application packaged using poetry2nix";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/23.11";
    poetry2nix = {
      url = "github:nix-community/poetry2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    poetry2nix,
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      # see https://github.com/nix-community/poetry2nix/tree/master#api for more functions and examples.
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (poetry2nix.lib.mkPoetry2Nix {inherit pkgs;}) mkPoetryApplication defaultPoetryOverrides;
    in {
      packages = {
        myapp = mkPoetryApplication {
          projectDir = self;
          preferWheels = true;
          overrides =
            defaultPoetryOverrides.extend
            (final: prev: {
              dppd = prev.dppd.overridePythonAttrs ( old: { buildInputs = (old.buildInputs or []) ++ [prev.setuptools]; });
              dppd-plotnine = prev.dppd-plotnine.overridePythonAttrs ( old: { buildInputs = (old.buildInputs or []) ++ [prev.setuptools]; });
            });
        };
        default = self.packages.${system}.myapp;
      };

      # Shell for app dependencies.
      #
      #     nix develop
      #
      # Use this shell for developing your app.
      devShells.default = pkgs.mkShell {
        inputsFrom = [self.packages.${system}.myapp];
      };

      # Shell for poetry.
      #
      #     nix develop .#poetry
      #
      # Use this shell for changes to pyproject.toml and poetry.lock.
      devShells.poetry = pkgs.mkShell {
        packages = [pkgs.poetry];
      };
    });
}
