// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

/// Example coin with a trusted manager responsible for minting/burning (e.g., a stablecoin)
/// By convention, modules defining custom coin types use upper case names, in contrast to
/// ordinary modules, which use camel case.
module huski::token {
    use std::option;
    use sui::coin::{Self, Coin, TreasuryCap};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::url;
    use std::ascii;

    //18446744073709551615
    const TOKEN_MAX_SUPPLY: u64 = 4200000000;

    /// Maximum supply overflow
    const ETokenOverMaxSupply: u64 = 144014;

    /// Name of the coin. By convention, this type has the same name as its parent module
    /// and has no fields. The full type of the coin defined by this module will be `COIN<TOKEN>`.
    struct TOKEN has drop {}

    #[allow(unused_function)]
    /// Register the managed currency to acquire its `TreasuryCap`. Because
    /// this is a module initializer, it ensures the currency only gets
    /// registered once.
    fun init(witness: TOKEN, ctx: &mut TxContext) {
        // Get a treasury cap for the coin and give it to the transaction sender
        let (treasury_cap, metadata) = coin::create_currency<TOKEN>(
            witness, 
            0, 
            b"HUSKI", 
            b"Huski Token", 
            b"Huski Platform Token", 
            option::some(url::new_unsafe(ascii::string(b"https://imgs-8qx.pages.dev/huski.png"))), 
            ctx
        );
        transfer::public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, tx_context::sender(ctx))
    }

    /// Manager can mint new coins
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<TOKEN>, amount: u64, recipient: address, ctx: &mut TxContext
    ) {
        assert!(coin::total_supply(treasury_cap) + amount <= TOKEN_MAX_SUPPLY, ETokenOverMaxSupply);
        coin::mint_and_transfer(treasury_cap, amount, recipient, ctx)
    }

    /// Manager can burn coins
    public entry fun burn(treasury_cap: &mut TreasuryCap<TOKEN>, coin: Coin<TOKEN>) {
        coin::burn(treasury_cap, coin);
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(TOKEN {}, ctx)
    }

}
