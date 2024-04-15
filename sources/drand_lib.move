// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module huski::drand_lib {
    use std::hash::sha2_256;
    use std::vector;

    /// Error codes
    const EInvalidRndLength: u64 = 0;
    
    #[test_only]
    const ROLL_MAX:u64 = 100;


    /// Derive a uniform vector from a drand signature.
    public fun derive_randomness(drand_sig: vector<u8>): vector<u8> {
        sha2_256(drand_sig)
    }

    // Converts the first 16 bytes of rnd to a u128 number and outputs its modulo with input n.
    // Since n is u64, the output is at most 2^{-64} biased assuming rnd is uniformly random.
    public fun safe_selection(n: u64, rnd: &vector<u8>): u64 {
        assert!(vector::length(rnd) >= 16, EInvalidRndLength);
        let m: u128 = 0;
        let i = 0;
        while (i < 16) {
            m = m << 8;
            let curr_byte = *vector::borrow(rnd, i);
            m = m + (curr_byte as u128);
            i = i + 1;
        };
        let n_128 = (n as u128);
        let module_128  = m % n_128;
        let res = (module_128 as u64);
        res
    }

    #[test_only]
    public fun test_rand():u64 {
        let digest = derive_randomness(b"TrueGame Platform Token");
        let result = safe_selection(ROLL_MAX, &digest);
        result
    }
}
