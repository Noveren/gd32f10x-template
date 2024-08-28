build:
    zig build -Doptimize=ReleaseSmall -Dclangd --summary all

clean:
    rm -rf ./.zig-cache