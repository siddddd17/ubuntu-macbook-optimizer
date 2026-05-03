# Ubuntu + XFCE Optimizer for MacBook Air (2017)

This repository contains a script that reproduces the exact optimizations applied on a MacBook Air 2017 (8GB RAM) running Ubuntu 22.04+ with XFCE.

## What it does

- Installs and enables **TLP** (advanced laptop power management)
- Configures **zRAM** (compressed RAM as swap – more efficient than disk swap)
- Sets CPU governor to **schedutil** (balanced performance/power)

These tweaks significantly improve memory efficiency, reduce SSD wear, and extend battery life on low‑resource MacBooks.

## Usage

```bash
git clone https://github.com/yourusername/ubuntu-macbook-optimizer.git
cd ubuntu-macbook-optimizer
chmod +x optimize-ubuntu-macbook.sh
./optimize-ubuntu-macbook.sh
