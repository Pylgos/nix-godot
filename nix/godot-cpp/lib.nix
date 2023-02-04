{ inputs, cell }:

let
  inherit (inputs) nixpkgs;
in
{
  buildGodotCpp = godot-headers:
    let
      libName = "libgodot-cpp.linux.template_debug.x86_64.a";
      cFlags = "-DDEBUG_ENABLED -DDEBUG_METHODS_ENABLED -I${godot-headers}";
      pkgConfigFile = nixpkgs.substituteAll {
        src = ./godot-cpp.pc;
        inherit libName godot-headers cFlags;
      };
    in
    nixpkgs.stdenv.mkDerivation {
      name = "godot-cpp";

      src = inputs.godot-cpp-source;

      postPatch = ''
        substituteInPlace ./SConstruct --replace \
        'Return("env")' \
        'env.PrependENVPath("PATH", os.getenv("PATH"))
        Return("env")'
      '';

      sconsFlags = [
        "gdextension_dir=${godot-headers}"
      ];

      installPhase = ''
        mkdir -p $out/lib
        cp bin/${libName} $out/lib
        cp -r include $out
        cp -r gen/include $out
        mkdir -p $out/lib/pkgconfig
        cp ${pkgConfigFile} $out/lib/pkgconfig/godot-cpp.pc
      '';

      buildInputs = with nixpkgs; [
        scons
      ];

      passthru = {
        inherit libName;
      };
    };
}
