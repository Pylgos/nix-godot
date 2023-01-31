{ inputs, cell }:
let
in
{
  godot-master-test-extension = nixpkgs.stdenv.mkDerivation {
    name = "test-extension";
    src = inputs.self + /test;
    cmakeFlags = [ "-GNinja" ];
    nativeBuildInputs = [ nixpkgs.cmake nixpkgs.ninja ];
    buildInputs = [ inputs.cells.godot.packages.godot-master.godot-cpp ];
  };
}