for pkg in python3-serial python3-smbus2 python3-spidev python3-gpiozero gpiod python3-libgpiod i2c-tools usbutils picocom; do
    echo "=== $pkg ==="
    dpkg-query -W -f='${Status} \| Version: ${Version}\\n' "$pkg" 2>/dev/null || echo "Not installed"
    apt-cache policy "$pkg" | grep -E "Installed:|Candidate:"
done