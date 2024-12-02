set -Eeuo pipefail
which python
which pip

# install_deps in debug

case "${TORCH_VERSION}" in
  *dev*) use_nightly_torch=1 ;;
  *    ) use_nightly_torch=0 ;;
esac

if [ ${use_nightly_torch} -eq 1 ]; then
  pip install --pre -U \
    setuptools_scm ninja Cython astunparse psutil \
    "torch==${TORCH_VERSION}" \
    -r requirements.txt --extra-index-url https://download.pytorch.org/whl/nightly/cu${CUDA_SHORT_VERSION} --no-cache-dir
else
  pip install -U \
    setuptools_scm ninja Cython astunparse psutil \
    "torch==${TORCH_VERSION}" \
    -r requirements.txt --extra-index-url https://download.pytorch.org/whl/cu${CUDA_SHORT_VERSION} --no-cache-dir
fi

apt install libfindbin-libs-perl

# Install NVIDIA cuDNN
set -Eeuo pipefail
has_cudnn=$(python -c "import importlib.util; assert importlib.util.find_spec('nvidia.cudnn') is not None" && echo 1 || echo 0)
if [ ${has_cudnn} -eq 0 ]; then
  cumajor=$(echo ${CUDA_SHORT_VERSION} | cut -c 1-2)
  cudnn_required=$(python -c "import torch; cudnn_version = torch.backends.cudnn.version(); print(f'{cudnn_version // (10000 if cudnn_version >= 90000 else 1000)}.{(cudnn_version // 100) % 10}')")
  python -c "import importlib.util; assert importlib.util.find_spec('nvidia.cudnn') is not None" || pip install "nvidia-cudnn-cu${cumajor}~=${cudnn_required}"
fi
