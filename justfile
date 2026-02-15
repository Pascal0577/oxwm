build:
    zig build -Doptimize=ReleaseSafe

install: build
    sudo cp zig-out/bin/oxwm /usr/bin/oxwm
    sudo cp resources/oxwm.desktop /usr/share/xsessions/oxwm.desktop
    sudo chmod +x /usr/bin/oxwm
    @echo "oxwm installed to /usr/bin/oxwm"

checkinstall:
    checkinstall --pkgname oxwm --exclude /root -y just install

uninstall:
    sudo rm -f /usr/bin/oxwm
    @echo "oxwm uninstalled"
    @echo "Your config at ~/.config/oxwm/ is preserved"

clean:
    rm -rf zig-out .zig-cache

test-clean:
    pkill Xephyr || true
    rm -rf ~/.config/oxwm
    Xephyr -screen 1280x800 :1 & sleep 1
    DISPLAY=:1 zig build run -- -c resources/config.lua

test:
    zig build xephyr

test-multimon:
    zig build xephyr-multi

edit:
    $EDITOR ~/.config/oxwm/config.lua

fmt:
    zig build fmt

pre-commit: fmt build
    @echo "All checks passed!"

run:
    zig build run
