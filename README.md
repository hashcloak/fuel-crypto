# fuel-crypto
Various Cryptographic Primitives in Sway for the Fuel VM

# Testing 

## Spin Up a Fuel node
From [here](https://fuellabs.github.io/sway/v0.19.0/introduction/overview.html).
In a separate tab in your terminal, spin up a local Fuel node:


`fuel-core --db-type in-memory`

This starts a Fuel node with a volatile database that will be cleared when shut down (good for testing purposes).

 Make sure `fuel-core` is up to date. This can be done with [fuelup](https://github.com/FuelLabs/fuelup). Also, make sure there's only 1 `fuel-core` installed (check this with `which -a fuel-core`).
 
## BLS

 To run tests for bls folder: 
 ```
 cd testing/tests_bls12_381
 forc test
 ```

## Running a script
Also to run a script a Fuel Node has to be spun up. You can use scripts locally to do intermediate tests. For example in `bls12_381/src` create `main.sw`. Start the file with `script;` and whatever code is in `fn main () { .. }` will be executed with the following command:

```
forc run --unsigned --pretty-print
```

The `--unsigned` part is to avoid signing with a contract. The `--pretty-print` is for if you do some logging; it will get printed nicely. 