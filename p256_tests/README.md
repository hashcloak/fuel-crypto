# Testing library p256

To test the p256 library with the Rust integration, we need a contract. In this separate project smart contract(s) reference directly the functions that need to be tested in p256.

## Running tests

Use forc >= `0.37.1`:

Documentation on installation can be found in the [Fuelup Book](https://install.fuel.network/master/basics.html).

### Build dependencies

Build all needed dependencies by running
```
forc build
```
in those folder.

At the moment the dependencies are: `p256` and `utils`.

### Run tests

```
cargo test
```

Alternatively, if you have some printing in the tests it is recommended to run: 

```
cargo test -- --nocapture
```

