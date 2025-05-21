# jetson-peripheral-drivers
A bash utility to compile and setup Jetson Linux kernel modules for adc, pwm and iio peripheries

## build.sh

A helper script to build Jetson Linux kernel modules for selected peripherals (currently PWM PCA9685).

### Prerequisites

* A Linux host with bash, tar, make, and `scripts/config` (provided in the kernel sources).

### Downloading BSP Sources

1. Go to NVIDIA’s Jetson Linux archive:
   [https://developer.nvidia.com/embedded/jetson-linux-archive](https://developer.nvidia.com/embedded/jetson-linux-archive)
2. Select the Jetson platform and release you’re targeting.
3. In the table, download **Driver Package (BSP) Sources** (e.g., `public_sources.tbz2`).
4. Save the tarball somewhere accessible.

### Usage

```bash
./build.sh [--pwm-pca9685] [--output-dir DIR] <public_sources.tbz2>
```

* `--pwm-pca9685` : Compile the PWM PCA9685 kernel module.
* `--output-dir DIR`: (Optional) Directory to copy the built `.ko` file (defaults to current directory).
* `<public_sources.tbz2>`: The downloaded BSP sources tarball.
