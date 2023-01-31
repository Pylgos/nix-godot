{ inputs, cell }:
let
  inherit (inputs) nixpkgs;
in
{
  godot-master-test-extension = nixpkgs.stdenv.mkDerivation {
    name = "test-extension";
    src = inputs.self + /test/godot-cpp-test;
    cmakeFlags = [ "-GNinja" ];
    nativeBuildInputs = [ nixpkgs.cmake nixpkgs.ninja ];
    buildInputs = [ inputs.cells.godot.packages.godot-master.godot-cpp ];
  };
}