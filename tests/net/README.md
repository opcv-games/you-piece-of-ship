# Online check (manual)

The GUT suite runs in one process, so it can't hold two separate games. This check runs a host and
a client as two headless Godot processes on this machine:

```bash
godot --headless -s tests/net/host_check.gd > /tmp/host.txt &
godot --headless -s tests/net/client_check.gd
cat /tmp/host.txt
```

Pass: the client is P2; the client's ship_x matches the host's (within about a metre: snapshots are
20 per second); the client's P2 moved right on both screens; both see the same number of items; when the host reaches port, the client shows the results screen.
