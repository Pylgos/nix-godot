{ inputs, cell }:

let
  nixpkgs = inputs.nixpkgs;
  l = nixpkgs.lib // builtins;

  buildGodot4 =
    { src
    , buildCache ? null
    , doCache ? false
    , cacheLimit ? 5000
    , production ? true
    , withPulseaudio ? true
    , withDbus ? true
    , withSpeechd ? true
    , withFontconfig ? true
    , withUdev ? true
    , withTouch ? true
    } @ args:
    let
      options = {
        pulseaudio = withPulseaudio;
        dbus = withDbus; # Use D-Bus to handle screensaver and portal desktop settings
        speechd = withSpeechd; # Use Speech Dispatcher for Text-to-Speech support
        fontconfig = withFontconfig; # Use fontconfig for system fonts support
        udev = withUdev; # Use udev for gamepad connection callbacks
        touch = withTouch; # Enable touch events
      };
      useCache = buildCache != null;

      self = nixpkgs.stdenv.mkDerivation (rec {
        pname = "godot";
        version = parseVersion src;
        inherit src;

        outputs = [ "out" "man" ] ++ l.optional doCache "buildCache";

        nativeBuildInputs = with nixpkgs; [
          pkg-config
          autoPatchelfHook
          installShellFiles
        ];

        buildInputs = with nixpkgs; [
          scons
        ]
        ++ runtimeDependencies
        # Necessary to make godot see fontconfig.lib and dbus.lib
        ++ l.optional withFontconfig fontconfig
        ++ l.optional withDbus dbus;

        runtimeDependencies = with nixpkgs; [
          vulkan-loader
          alsa-lib
          xorg.libX11
          xorg.libXcursor
          xorg.libXinerama
          xorg.libXi
          xorg.libXrandr
          xorg.libXext
          xorg.libXfixes
          libGLU
          libGL
        ]
        ++ l.optional withPulseaudio libpulseaudio
        ++ l.optional withDbus dbus.lib
        ++ l.optional withSpeechd speechd
        ++ l.optional withFontconfig fontconfig.lib
        ++ l.optional withUdev udev;


        postPatch = ''
          substituteInPlace ./platform/linuxbsd/detect.py \
            --replace '        env.ParseConfig("pkg-config xi --cflags")' \
                      '        env.ParseConfig("pkg-config xi --cflags")${"\n"}        env.ParseConfig("pkg-config xfixes --cflags")'
        '';

        enableParallelBuilding = true;

        sconsFlags = "platform=linuxbsd target=editor production=${if production then "true" else "false"}"
          + (if (!doCache && useCache) then " --cache-readonly" else "");

        preConfigure = ''
          sconsFlags+=" ${
            l.concatStringsSep " "
            (l.mapAttrsToList (k: v: "${k}=${l.toJSON v}") options)
          }"
        '' + (
          if (doCache && useCache) then
            ''
              cp -a ${buildCache} $buildCache
              export SCONS_CACHE=$buildCache
              export SCONS_CACHE_LIMIT=${cacheLimit}
            ''
          else if (!doCache && useCache) then
            ''
              export SCONS_CACHE=${buildCache}
            ''
          else if (doCache && !useCache) then
            ''
              export SCONS_CACHE=$buildCache
              export SCONS_CACHE_LIMIT=${cacheLimit}
            ''
          else ""
        );

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

        passthru = {
          buildIncremental = newArgs:
            let
              cachedGodot = buildGodot4 (args // { doCache = true; });
            in
            buildGodot4 (newArgs // { buildCache = cachedGodot.buildCache; });
        };

        meta = {
          homepage = "https://godotengine.org";
          description = "Free and Open Source 2D and 3D game engine";
          license = l.licenses.mit;
          platforms = [ "i686-linux" "x86_64-linux" ];
        };
      } // args);
    in
    self;

  parseVersion = source:
    let
      s = l.readFile (source + /version.py);
      f = t: l.elemAt (l.match ".+${t}[ ]*=[ ]*([^\n]+).+" s) 0;
      major = f "major";
      minor = f "minor";
      patch = f "patch";
      status = l.fromJSON (f "status");
    in
    "${major}.${minor}.${patch}-${status}";

in
{
  inherit buildGodot4;
}
