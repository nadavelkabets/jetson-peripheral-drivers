# jetson-peripheral-drivers
A bash utility to compile and setup Jetson Linux kernel modules for adc, pwm and iio peripheries

In future releases, **Device Tree Overlays** will be included to automate board configuration as well.

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

> **⚠️ Important Note**
> This script must currently be executed **on the Jetson device itself**; cross-compilation is not supported.
### Usage

```bash
./build.sh [--pwm-pca9685] [--ads1015] [--sc16is7xx] [--output-dir DIR] <public_sources.tbz2>
```

* `--pwm-pca9685` : Compile the PWM PCA9685 kernel module.
* `--ads1015` : Compile the IIO ADC ADS1015 kernel module.
* `--sc16is7xx` : Compile the SC16IS7XX I2C/SPI to UART bridge kernel module.
* `--output-dir DIR`: (Optional) Directory to copy the built `.ko` file (defaults to current directory).
* `<public_sources.tbz2>`: The downloaded BSP sources tarball.

### Installation and Testing

After building, the module `.ko` file should be placed into the kernel modules tree for your running kernel:

```bash
sudo install -m 644 pwm-pca9685.ko /lib/modules/$(uname -r)/kernel/drivers/pwm/
```

Then update the module dependency list:

```bash
sudo depmod -a
```

To verify the module is available (either by filesystem or via modprobe):

```bash
modprobe -l | grep pwm_pca9685
```

#### Loading and Listing Modules

* **Load the module**:

  ```bash
  sudo modprobe pwm-pca9685
  ```
* **Check that it’s loaded**:

  ```bash
  lsmod | grep pwm_pca9685
  ```
* **View module information**:

  ```bash
  modinfo pwm-pca9685
  ```

### Debugging

If you encounter issues loading or running the module, check:

* Kernel messages: `dmesg | tail -n 50`
* System logs: `journalctl -k --since "5 minutes ago"`
* Driver‑specific logs: filter for the driver name, e.g.:

  ```bash
  dmesg | grep -i pca9685
  journalctl -k | grep -i pca9685
  ```

These commands can help you identify configuration errors, missing dependencies, or driver load failures.
