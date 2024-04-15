// Copyright (c) 2023, Vivid Network Contributors
// SPDX-License-Identifier: Apache-2.0

module huski::utils {

    use std::vector;
    use sui::pay;
    use sui::coin::{ Self, Coin };
    use sui::balance::{ Self, Supply, Balance };
    use sui::transfer;
    use sui::clock::{ Self, Clock };
    use sui::tx_context::{ Self, TxContext };

    const ClockEpochMultiplier: u64 = 86400u64 * 1000u64;

    /// Not enough balance for operation
    const EUtilsNotEnoughBalance: u64 = 154001;

    public fun get_epoch(clock: &Clock): u64 {
        clock::timestamp_ms(clock) / ClockEpochMultiplier
    }

    public fun merge_coins<T>(cs: vector<Coin<T>>, ctx: &mut TxContext): Coin<T> {
        if (vector::length(&cs) == 0) {
            let c = coin::zero<T>(ctx);
            vector::destroy_empty(cs);
            c
        }
        else {
            let c = vector::pop_back(&mut cs);
            pay::join_vec(&mut c, cs);
            c
        }
    }

    public fun merge_coins_to_amount_and_transfer_back_rest<T>(cs: vector<Coin<T>>, amount: u64, ctx: &mut TxContext): Coin<T> {
        let c = merge_coins(cs, ctx);
        assert!(coin::value(&c) >= amount, EUtilsNotEnoughBalance);

        let c_out = coin::split(&mut c, amount, ctx);

        let sender = tx_context::sender(ctx);
        transfer_or_destroy_zero(c, sender);
        
        c_out
    }

    public fun transfer_or_destroy_zero<X>(c: Coin<X>, addr: address) {
        if (coin::value(&c) > 0) {
            transfer::public_transfer(c, addr);
        }
        else {
            coin::destroy_zero(c);
        }
    }

    public fun mint_from_supply<T>(s: &mut Supply<T>, amount: u64, recipient: address, ctx: &mut TxContext) {
        let mint_balance = balance::increase_supply(s, amount);
        let coin = coin::from_balance(mint_balance, ctx);
        transfer::public_transfer(coin, recipient);
    }

    /// Join the balance without destorying it
    public fun join_balance<X>(b1: &mut Balance<X>, b2: &mut Balance<X>) {
        let b2_amount = balance::value(b2);
        join_balance_with_amount(b1, b2, b2_amount);
    }

    public fun join_balance_with_amount<X>(b1: &mut Balance<X>, b2: &mut Balance<X>, amount: u64) {
        let b3 = balance::split(b2, amount);
        balance::join(b1, b3);
    }
}

