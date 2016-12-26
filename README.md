# Exbandwidth

This is a bandwidth monitor built using Elixir and meant to be installed on a
Raspberry PI using Nerves.
It should show the internet bandwidth consumption from any SNMP capable router.

In a very brief summary it works as follows: it uses
[SNMP](https://it.wikipedia.org/wiki/Simple_Network_Management_Protocol)
(Simple Network Management Protocol) to get the WAN data rates from the router
and then displays these results.

# Running

Launch:

```shell
$ iex -S mix
```

# Tests

```shell
$ mix test --no-start
```
