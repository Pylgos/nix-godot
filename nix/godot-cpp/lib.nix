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

      patches = [ ./cmake-install.patch ];

      cmakeFlags = [
        "-DGODOT_GDEXTENSION_DIR=${godot-headers}"
        "-GNinja"
      ];

      nativeBuildInputs = with nixpkgs; [
        cmake
        python3
        ninja
      ];

      passthru = { };
    };

}
