# fuel-crypto
Various Cryptographic Primitives in Sway for the Fuel VM

# Testing 

Note: Testing for `p256` is done in `p256_tests`, instructions can be found in `p256_tests/README.md`.

For testing we use `fuels`, read about it [here](https://fuellabs.github.io/fuels-rs/v0.25.0/). 

## BLS

 To run tests for bls folder: 
 ```
 cd testing/tests_bls12_381
 forc test
 ```

## Testing with a script
You can use scripts locally to do intermediate tests. To run a script a local Fuel node must be spun up.

### Spin Up a Fuel node
From [here](https://fuellabs.github.io/sway/v0.19.0/introduction/overview.html).
In a separate tab in your terminal, spin up a local Fuel node:


`fuel-core --db-type in-memory`

This starts a Fuel node with a volatile database that will be cleared when shut down (good for testing purposes).

 Make sure `fuel-core` is up to date. This can be done with [fuelup](https://github.com/FuelLabs/fuelup). Also, make sure there's only 1 `fuel-core` installed (check this with `which -a fuel-core`).
 
 ### Create and run a script

For example in `bls12_381/src` create `main.sw`. Change in `bls12_381/Forc.toml` `entry` to `main.sw`. 

Start the file with `script;` and whatever code is in `fn main () { .. }` will be executed with the following command:

```
forc run --unsigned --pretty-print
```

The `--unsigned` part is to avoid signing with a contract. The `--pretty-print` is for if you do some logging; it will get printed nicely. 

# FuelVM Instruction Set

Find all assembly instructions that can be used [here](https://github.com/FuelLabs/fuel-specs/blob/master/specs/vm/instruction_set.md#sub-subtract). 