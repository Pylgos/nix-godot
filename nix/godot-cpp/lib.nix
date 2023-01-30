{ inputs, cell }:

let
  inherit (inputs) nixpkgs;
in
{
  buildGodotCpp = godot-headers:
    let in
    nixpkgs.stdenv.mkDerivation {
      name = "godot-cpp";

      src = inputs.godot-cpp-source;

      cmakeFlags = [
        "-DGODOT_GDEXTENSION_DIR=${godot-headers}"
      ];

      nativeBuildInputs = with nixpkgs; [
        cmake
        python3
      ];
    };
}
