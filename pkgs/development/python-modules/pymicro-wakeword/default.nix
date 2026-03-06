{
  lib,
  stdenv,
  autoPatchelfHook,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  numpy,
  pymicro-features,
  pytestCheckHook,
}:

buildPythonPackage rec {
  pname = "pymicro-wakeword";
  version = "2.2.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "OHF-Voice";
    repo = "pymicro-wakeword";
    tag = "v${version}";
    hash = "sha256-PLGwpmmiLwpDn+Dh5HhaE2w7hJLC0xK/wsuhxxR8rwU=";
  };

  postPatch = ''
    python ./script/copy_lib
  '';

  nativeBuildInputs = [
    autoPatchelfHook
  ];

  build-system = [
    setuptools
  ];

  dependencies = [
    numpy
    pymicro-features
  ];

  nativeCheckInputs = [
    pytestCheckHook
  ];

  pythonImportsCheck = [ "pymicro_wakeword" ];

  meta = {
    # vendors prebuilt libtensorflowlite_c.so
    broken = stdenv.hostPlatform.isDarwin;
    description = "Python library for microWakeWord wake word detection";
    homepage = "https://github.com/OHF-Voice/pymicro-wakeword";
    changelog = "https://github.com/OHF-Voice/pymicro-wakeword/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ takac ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
