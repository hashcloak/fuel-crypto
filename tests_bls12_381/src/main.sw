contract;

use bls12_381::{fp::*};

abi BlsTestContract {
    #[storage(write)]fn initialize_counter(value: u64) -> u64;
    #[storage(read, write)]fn increment_counter(amount: u64) -> u64;
}

storage {
    counter: u64 = 0,
}

impl BlsTestContract for Contract {
    #[storage(write)]fn initialize_counter(value: u64) -> u64 {
        storage.counter = value;
        value
    }

    #[storage(read, write)]fn increment_counter(amount: u64) -> u64 {
        let incremented = storage.counter + amount;
        storage.counter = incremented;
        incremented
    }
}
