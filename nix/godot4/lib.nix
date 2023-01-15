{ inputs, cell, nixpkgs }:

let
  l = nixpkgs.lib // builtins;

  makeGodot4 = { source }:
    nixpkgs.mkDerivation {
      pname = "godot";
      version = parseVersion source;
      src = source;

      nativeBuildInputs = [
        pkg-config
        autoPatchelfHook
        installShellFiles
      ];

      buildInputs = [
        scons
        libGLU
        libX11
        libXcursor
        libXinerama
        libXi
        libXrandr
        libXext
        libXfixes
      ]
      ++ runtimeDependencies
      # Necessary to make godot see fontconfig.lib and dbus.lib
      ++ lib.optional withFontconfig fontconfig
      ++ lib.optional withDbus dbus;

      runtimeDependencies = [
        vulkan-loader
        alsa-lib
      ]
      ++ lib.optional withPulseaudio libpulseaudio
      ++ lib.optional withDbus dbus.lib
      ++ lib.optional withSpeechd speechd
      ++ lib.optional withFontconfig fontconfig.lib
      ++ lib.optional withUdev udev;

      patches = [
        # Godot expects to find xfixes inside xi, but nix's pkg-config only
        # gives the libs for the requested package (ignoring the propagated-build-inputs)
        ./xfixes.patch
      ];

      enableParallelBuilding = true;

      sconsFlags = "platform=linuxbsd target=editor production=true";
      preConfigure = ''
        sconsFlags+=" ${
          lib.concatStringsSep " "
          (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)
        }"
      '';

      outputs = [ "out" "man" ];

      installPhase = ''
        mkdir -p "$out/bin"
        cp bin/godot.* $out/bin/godot
        installManPage misc/dist/linux/godot.6
        mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
        cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
        substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
          --replace "Exec=godot" "Exec=$out/bin/godot"
        cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
        cp icon.png "$out/share/icons/godot.png"
      '';

      meta = with lib; {
        homepage = "https://godotengine.org";
        description = "Free and Open Source 2D and 3D game engine";
        license = licenses.mit;
        platforms = [ "i686-linux" "x86_64-linux" ];
        maintainers = with maintainers; [ twey shiryel ];
      };
    };

  parseVersion = source:
    let
      s = l.readFile source + /version.py;
      f = t: l.elemAt (l.match ''${t}[[:space:]]*=[[:space:]]*([^\n]+)'' s) 0;
      major = f "major";
      minor = f "minor";
      patch = f "patch";
      status = f "status";
    in
    "${major}.${minor}.${patch}-${status}";

in
{ }
