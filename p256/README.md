# Build

Using forc >= `0.37.1`:
```
forc build
```
Documentation on installation can be found in the [Fuelup Book](https://install.fuel.network/master/basics.html).

Some warning such as `This cast, from integer type of width sixty four to integer type of width eight, will lose precision.` will appear. Currently Sway does implicit conversion and there is no way to surpress the warning. The team plans to remove implicit conversion.

# Running a script

Add script code to `main.sw` and run the script with 

```
fuel-core --db-type in-memory
forc run --unsigned --pretty-print
```

For this change `entry = "lib.sw"` to `entry = "main.sw"` in `Forc.toml`. 