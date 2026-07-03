# HOWTO — heirloom-tests-darwin

## SCAFFOLD phase (current state)

You can clone + inspect the harness structure but cannot run it
because Apout is not yet available:

```sh
git clone https://github.com/moonman81/heirloom-tests-darwin
cd heirloom-tests-darwin
ls corpora/ harness/
cat harness/compare-tool.sh
```

## Once Apout is ported (future)

```sh
# 1. Ensure Heirloom installed
sudo make -C /opt/heirloom/src/workspace install

# 2. Fetch + extract V7
mkdir -p /opt/heirloom/upstream-ancestors/v7
curl -L https://www.tuhs.org/Archive/Distributions/Research/Henry_Spencer_v7/v7.tar.gz \
    -o /tmp/v7.tar.gz
tar xzf /tmp/v7.tar.gz -C /opt/heirloom/upstream-ancestors/v7

# 3. Build Apout (once the port exists)
cd vendor/apout && make

# 4. Run the harness
cd -
sh harness/run-all.sh

# 5. Inspect drift reports
ls reports/
```

## Contributing an Apout patch

See `APOUT-STATUS.md` for the current porting status + what remains.
