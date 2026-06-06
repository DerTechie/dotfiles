export EDITOR=nvim
export LIBVIRT_DEFAULT_URI='qemu:///system'
export DOCKER_HOST="unix:///run/user/$(id -u)/podman/podman.sock"

# herd-lite PHP — .local/bin prepended last so it wins precedence
export PATH="$HOME/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="$HOME/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
export PATH="$HOME/.local/bin:$PATH"
