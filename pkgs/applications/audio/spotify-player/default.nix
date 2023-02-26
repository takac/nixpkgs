{ lib
, rustPlatform
, fetchFromGitHub
, pkg-config
, openssl
, cmake
, alsa-lib
, dbus
, fontconfig
, libsixel
, stdenv
, darwin
, makeWrapper
# build options
, withStreaming ? true
, withDaemon ? true
, withAudioBackend ? "rodio"
, withMediaControl ? true
, withLyrics ? true
, withImage ? true
, withNotify ? true
, withSixel ? true
}:

rustPlatform.buildRustPackage rec {
  pname = "spotify-player";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "aome510";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-5+YBlXHpAzGgw6MqgnMSggCASS++A/WWomftX8Jxe7g=";
  };

  cargoHash = "sha256-PIYaJC3rVbPjc2CASzMGWAzUdrBwFnKqhrZO6nywdN8=";

  nativeBuildInputs = [
    pkg-config
    cmake
    rustPlatform.bindgenHook
  ] ++ lib.optional stdenv.isDarwin [
    makeWrapper
  ];

  buildInputs = [
    openssl
    dbus
    fontconfig
  ] ++ lib.optionals withSixel [
    libsixel
  ] ++ lib.optionals stdenv.isLinux [
    alsa-lib
  ] ++ lib.optionals stdenv.isDarwin
    (with darwin.apple_sdk.frameworks; [
      MediaPlayer
      AppKit
      AudioUnit
      Cocoa
    ]);

  buildNoDefaultFeatures = true;

  buildFeatures = [ ]
    ++ lib.optionals (withAudioBackend != "") [ "${withAudioBackend}-backend" ]
    ++ lib.optionals withMediaControl [ "media-control" ]
    ++ lib.optionals withImage [ "image" ]
    ++ lib.optionals withLyrics [ "lyric-finder" ]
    ++ lib.optionals withDaemon [ "daemon" ]
    ++ lib.optionals withNotify [ "notify" ]
    ++ lib.optionals withStreaming [ "streaming" ]
    ++ lib.optionals withSixel [ "sixel" ];

  # sixel-sys is dynamically linked to libsixel
  postInstall = lib.optional (stdenv.isDarwin && withSixel) ''
    wrapProgram $out/bin/spotify_player \
      --prefix DYLD_LIBRARY_PATH : "${lib.makeLibraryPath [libsixel]}"
  '';

  meta = with lib; {
    description = "A fast, easy to use, and configurable terminal music player";
    homepage = "https://github.com/aome510/spotify-player";
    changelog = "https://github.com/aome510/spotify-player/releases/tag/v${version}";
    mainProgram = "spotify_player";
    license = licenses.mit;
    maintainers = with maintainers; [ dit7ya xyven1 ];
  };
}
