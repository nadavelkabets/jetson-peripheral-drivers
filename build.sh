#!/bin/bash
# build.sh
# A utility to build Jetson Linux kernel module drivers for specified peripherals.
# Currently supports PWM PCA9685.
# Usage:
#   ./build.sh [--pwm-pca9685] [--ads1015] [--output-dir DIR] <public_sources.tbz2>

set -euo pipefail

# Supported peripherals
SUPPORTED=(pwm-pca9685 ads1015)
# Selected peripherals
declare -a SELECTED=()

# Default output directory
OUTDIR="$PWD"

# Print usage information
usage() {
  echo "Usage: $0 [options] <public_sources.tbz2>"
  echo
  echo "Options:"
  for periph in "${SUPPORTED[@]}"; do
    echo "  --${periph}       Compile driver for ${periph^^} peripheral"
  done
  echo "  --output-dir DIR    Specify output directory (defaults to current directory)"
  echo "  --help              Show this help message and exit"
  exit 1
}

# Ensure at least one argument
if [[ $# -lt 1 ]]; then
  usage
fi

# Parse options until only the tar file remains
while [[ $# -gt 1 ]]; do
  case "$1" in
    --help)
      usage
      ;;
    --output-dir)
      if [[ -n "${2:-}" && -d "$2" ]]; then
        OUTDIR="$2"
        shift 2
      else
        echo "Error: --output-dir requires a valid directory argument"
        exit 1
      fi
      ;;
    --*)
      opt="${1#--}"
      # Exact match against supported peripherals
      for s in "${SUPPORTED[@]}"; do
        if [[ "$s" == "$opt" ]]; then
          SELECTED+=("$opt")
          shift
          continue 2
        fi
      done
      echo "Error: Unsupported option '$1'"
      usage
      ;;
    *)
      echo "Error: Unexpected option or argument '$1'"
      usage
      ;;
  esac
done

# Remaining argument is the tar file
TARFILE="$1"
if [[ ! -f "$TARFILE" ]]; then
  echo "Error: File '$TARFILE' not found"
  exit 1
fi

# Validate tar file
if ! tar -tjf "$TARFILE" >/dev/null 2>&1; then
  echo "Error: '$TARFILE' is not a valid bzip2 tar archive"
  exit 1
fi

# Ensure at least one peripheral was selected
if [[ ${#SELECTED[@]} -eq 0 ]]; then
  echo "Error: No peripheral specified"
  usage
fi

# Show configuration summary
echo "Selected peripherals: ${SELECTED[*]}"
echo "Using output directory: $OUTDIR"

# Intall dependencies
sudo apt install -y tar build-essential ncurses-dev xz-utils libssl-dev bc flex libelf-dev bison

# Create temporary workspace
echo "Creating temporary workspace..."
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Extract public sources
echo "Extracting public sources to '$TMPDIR'..."
tar -xjf "$TARFILE" -C "$TMPDIR"

# Extract kernel sources
echo "Extracting kernel sources..."
pushd "$TMPDIR/Linux_for_Tegra/source/public" > /dev/null
tar -xjf kernel_src.tbz2
popd > /dev/null

# Locate exact kernel source directory
KERNEL_SRC_DIR=$(find "$TMPDIR/Linux_for_Tegra/source/public/kernel" -maxdepth 1 -type d -name 'kernel-*' | head -n 1)
if [[ -z "$KERNEL_SRC_DIR" ]]; then
  echo "Error: Kernel source directory not found"
  exit 1
fi

# Enter kernel source directory
echo "Configuring kernel at $KERNEL_SRC_DIR..."
pushd "$KERNEL_SRC_DIR" > /dev/null
# Initial default config
make olddefconfig
# Set version prefix
scripts/config --set-str CONFIG_LOCALVERSION "-tegra"

# Define configuration functions for peripherals
configure_pwm_pca9685() {
  echo "Configuring I2C and PCA9685 support..."
  scripts/config --enable CONFIG_I2C
  scripts/config --enable CONFIG_I2C_CHARDEV
  scripts/config --module CONFIG_PWM_PCA9685
}

configure_ads1015() {
  echo "Configuring IIO and ADS1015 support..."
  scripts/config --enable CONFIG_IIO
  scripts/config --enable CONFIG_IIO_CHARDEV
  scripts/config --module CONFIG_IIO_ADS1015
}

# Invoke configuration for each selected peripheral
for periph in "${SELECTED[@]}"; do
  cfg_fn="configure_${periph//-/_}"
  if declare -f "$cfg_fn" >/dev/null; then
    $cfg_fn
  else
    echo "Warning: No configure function defined for $periph"
  fi
done

# Re-run default config to apply changes
make olddefconfig
make prepare
make modules_prepare
popd > /dev/null

# Define compile functions for peripherals
compile_pwm_pca9685() {
  echo "Compiling PWM PCA9685 module..."
  pushd "$KERNEL_SRC_DIR" > /dev/null
  make drivers/pwm/pwm-pca9685.ko
  cp drivers/pwm/pwm-pca9685.ko "$OUTDIR"
  popd > /dev/null
  echo "pwm-pca9685.ko has been copied to $OUTDIR"
}

compile_ads1015() {
  echo "Compiling ADS1015 ADC module..."
  pushd "$KERNEL_SRC_DIR" > /dev/null
  make drivers/iio/adc/ti-ads1015.ko
  cp drivers/iio/adc/ti-ads1015.ko "$OUTDIR"
  popd > /dev/null
  echo "ads1015.ko has been copied to $OUTDIR"
}

# Build each selected peripheral
for periph in "${SELECTED[@]}"; do
  build_fn="compile_${periph//-/_}"
  if declare -f "$build_fn" >/dev/null; then
    $build_fn
  else
    echo "Warning: No compile function defined for $periph"
  fi
done

echo "All done."
