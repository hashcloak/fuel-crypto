# fuel-crypto
Various Cryptographic Primitives in Sway for the Fuel VM

# Testing 

 Make sure `fuel-core` is up to date. This can be done with [fuelup](https://github.com/FuelLabs/fuelup). Also, make sure there's only 1 `fuel-core` installed (check this with `which -a fuel-core`).

## Edwards25519

 The testing is done in Rust; the testfiles are in `/test_contract`. See reference in [Sway documentation](https://fuellabs.github.io/sway/v0.17.0/testing/testing-with-rust.html).
 
 In `main.sw` the contract makes the connection with the library code in edward25519. This in turn can be tested in the `/test_contract/tests` folder. 

 To run tests for edwards25519 folder: 
 ```
 cd test_contract
 forc test
 ```
 
## BLS

 To run tests for bls folder: 
 ```
 cd tests-bls
 forc test
 ```
