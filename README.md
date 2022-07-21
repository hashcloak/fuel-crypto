# fuel-crypto
Various Cryptographic Primitives in Sway for the Fuel VM

# Testing 

 Make sure `fuel-core` is up to date. This can be done with [fuelup](https://github.com/FuelLabs/fuelup). Also, make sure there's only 1 `fuel-core` installed. 

## Edwards25519

 The testing is done in Rust; the testfiles are in `/test_contract`. In `main.sw` the contract makes the connection with the library code in edward25519. This in turn can be tested in the `/test_contract/tests` folder. 

 To run tests for edwards25519 folder: 
 ```
 cd test_contract
 forc test
 ```
 
