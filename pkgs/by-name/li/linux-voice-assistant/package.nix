{
  lib,
  python3Packages,
  fetchFromGitHub,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "linux-voice-assistant";
  version = "1.1.5";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "OHF-Voice";
    repo = "linux-voice-assistant";
    tag = "v${finalAttrs.version}";
    hash = "sha256-whpjjWDF0p/hegJLezz8XOdYPmsU3HftJ7BroJ5hL5E=";
  };

  postPatch = ''
    # python-mpv is packaged as 'mpv' in nixpkgs; align the requirement name.
    substituteInPlace pyproject.toml \
      --replace-fail '"python-mpv>=1,<2"' '"mpv>=1,<2"'
  '';

  build-system = with python3Packages; [
    setuptools
  ];

  # Upstream pins aioesphomeapi to an older exact version; relax to use the
  # version available in nixpkgs.
  pythonRelaxDeps = [
    "aioesphomeapi"
  ];

  dependencies = with python3Packages; [
    aioesphomeapi
    getmac
    mpv
    netifaces2
    numpy
    pymicro-wakeword
    pyopen-wakeword
    soundcard
    zeroconf
  ];

  # Upstream omits a console_scripts entry point; create one that drives the
  # async main() via asyncio.run().  The buildPythonApplication wrapPythonPrograms
  # phase will add the correct PYTHONPATH to this script automatically.
  postInstall = ''
    mkdir -p "$out/bin"
    cat > "$out/bin/linux-voice-assistant" <<'EOF'
#!/usr/bin/env python3
import asyncio
from linux_voice_assistant.__main__ import main
asyncio.run(main())
EOF
    chmod +x "$out/bin/linux-voice-assistant"
  '';

  # No unit tests are included in the source tree.
  doCheck = false;

  pythonImportsCheck = [ "linux_voice_assistant" ];

  meta = {
    description = "Linux voice satellite for Home Assistant using the ESPHome protocol";
    homepage = "https://github.com/OHF-Voice/linux-voice-assistant";
    changelog = "https://github.com/OHF-Voice/linux-voice-assistant/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ takac ];
    mainProgram = "linux-voice-assistant";
    platforms = lib.platforms.linux;
  };
})
