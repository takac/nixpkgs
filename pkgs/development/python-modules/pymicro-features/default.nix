{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  wheel,
  pytestCheckHook,
  syrupy,
}:

buildPythonPackage rec {
  pname = "pymicro-features";
  version = "2.0.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "rhasspy";
    repo = "pymicro-features";
    tag = "v${version}";
    hash = "sha256-bCvrsvifUxM7jfqBePmcYviZ5pIy1ZApq48Pu/5b7AM=";
  };

  build-system = [
    setuptools
    wheel
  ];

  nativeCheckInputs = [
    pytestCheckHook
    syrupy
  ];

  pythonImportsCheck = [ "pymicro_features" ];

  meta = {
    description = "Speech features using TFLite Micro audio frontend";
    homepage = "https://github.com/rhasspy/pymicro-features";
    changelog = "https://github.com/rhasspy/pymicro-features/blob/v${version}/CHANGELOG.md";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ takac ];
  };
}
