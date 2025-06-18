# Elixir Common

_Shared modules and utilities for Elixir services at Together AI_

---

## What is this?

Together uses the [Elixir programming language](https://elixir-lang.org/) for several of its services.
Along with the [Phoenix web framework](https://phoenixframework.org/) and [gRPC libraries](https://github.com/elixir-grpc/grpc), we're able to build high-traffic, fault-tolerant systems to serve our customers.

This repository contains modules and utilities that are used by multiple services.
We **do not** expect anyone outside of Together to use the code in this repository, but it may serve as inspiration for your next project.


## Installation

This repository is not available from Hex.pm, and instead should be installed from GitHub:

```elixir
def deps do
  [
    {:together, github: "togethercomputer/elixir-common"}
  ]
end
```


## License

Please see [LICENSE](LICENSE) for licensing details.
