# P256 testing

All P256 (library) functionality is tested with the Rust testing framework by using smart contracts that call all library functions to be tested. For example: testing curve arithmetic is done by testing the smart contract in folder `curve_test`, which contains functions that directly loop those functions.

## Run tests

First, build the necessary dependencies. Run in both `p256/lib` and `utils`:
```
forc build
```

Then, build the test project. For example, to test curve arithmetic:
```
cd curve_test
forc build
```

Finally, run the tests (in `harness.rs`):
````
cargo test
```