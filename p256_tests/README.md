# Testing library p256

To test the p256 library with the Rust integration, we need a contract. In this separate project smart contract(s) reference directly the functions that need to be tested in p256.

## Running tests

```
forc build
cargo test
#cargo test -- --nocapture
```