module huski::bank {
    use sui::object::{Self, UID, ID};
    use sui::balance::{Self, Balance};
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::tx_context::{Self, TxContext};
    use huski::token::{TOKEN};
    use sui::package::{Self,Publisher};
    use sui::transfer;
    use sui::event;
    use sui::table::{ Self, Table };
    use huski::utils::{ Self };
    // use std::debug;

    /// Error codes
    // const EGameNotInProgress: u64 = 0;
    // const EGameAlreadyCompleted: u64 = 1;
    // const EInvalidRandomness: u64 = 2;
    const EInvalidNumber: u64 = 3;

    /// Game status
    // const IN_PROGRESS: u8 = 0;
    // const CLOSED: u8 = 1;
    // const COMPLETED: u8 = 2;

    /// Attempt to get the most recent created object ID when none has been created.
    // const ENoIDsCreated: u64 = 1;

    /// For when empty vector is supplied into join function.
    // const ENoCoins: u64 = 0;

    /// For when supplied Coin is zero.
    const EZeroAmount: u64 = 0;

    /// For when pool fee is set incorrectly.
    /// Allowed values are: [0-10000).
    // const EWrongFee: u64 = 1;

    /// For when someone tries to swap in an empty pool.
    // const EReservesEmpty: u64 = 2;

    /// For when initial LSP amount is zero.
    // const EShareEmpty: u64 = 3;

    /// For when someone attempts to add more liquidity than u128 Math allows.
    // const EPoolFull: u64 = 4;

    /// Trying to claim ownership of a type with a wrong `Publisher`.
    const ENotOwner: u64 = 0;

    /// For when supplied Coin is zero.
    const ETokenInvalidParameter: u64 = 14400;



    struct BANK has drop {}

    struct Bank has key, store {
        id: UID,
        SUI: Balance<SUI>,
        HUSKI: Balance<TOKEN>,
    }

    #[allow(unused_function)]
    fun init(otw: BANK,_: &mut TxContext) {
        create_bank(_);
        package::claim_and_keep(otw, _);
    }

    fun create_bank(
        ctx: &mut TxContext
    ) {
        let bank=Bank {
            id: object::new(ctx),
            SUI: balance::zero(),
            HUSKI: balance::zero(),
        };
        transfer::public_share_object(bank);
    }

    public entry fun add_sui_to_bank(
        bank: &mut Bank, 
        sui: Coin<SUI>
    ) {
        assert!(coin::value(&sui) > 0, EZeroAmount);
        balance::join(&mut bank.SUI, coin::into_balance(sui));
    }

    public entry fun add_huski_to_bank(
        bank: &mut Bank, 
        token: Coin<TOKEN>
    ) {
        assert!(coin::value(&token) > 0, EZeroAmount);
        balance::join(&mut bank.HUSKI, coin::into_balance(token));
    }

    public entry fun remove_sui_from_bank(
        publisher: &Publisher,
        bank: &mut Bank,
        amount:u64,
        ctx: &mut TxContext
    ) {
        assert!(package::from_package<BANK>(publisher), ENotOwner);
        assert!(amount <= balance::value(&bank.SUI), EInvalidNumber);
        let sui=coin::take(&mut bank.SUI, amount, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(sui, sender)
    }

    public entry fun remove_huski_from_bank(
        publisher: &Publisher,
        bank: &mut Bank,
        amount:u64,
        ctx: &mut TxContext
    ) {
        assert!(package::from_package<BANK>(publisher), ENotOwner);
        assert!(amount <= balance::value(&bank.HUSKI), EInvalidNumber);
        let token=coin::take(&mut bank.HUSKI, amount, ctx);
        let sender = tx_context::sender(ctx);
        transfer::public_transfer(token, sender)
    }

    #[test_only]
    /// Wrapper of module initializer for testing
    public fun test_init(ctx: &mut TxContext) {
        init(BANK {}, ctx)
    }








    /// Cannot not buy ido due to is not public and you are not in the whitelist
    const ETokenIdoCannotBuyPermissionDenied: u64 = 144005;


    struct AddTokenIdoWhitelistEvent has copy, drop {
        /// The id of the ido
        ido_id: ID,
    }

    struct BuyTokenIdoTokenEvent has copy, drop {
        /// The id of the ido
        ido_id: ID,
        /// The in amount
        in_amount: u64,
        /// The out amount
        out_amount: u64
    }

    struct TokenIdo has key {
        /// The id of the token ido event
        id: UID,
        /// The name of the ido event
        name: vector<u8>,
        /// The price of the ido, relative to SUI, in e9 format, which means when price = 10^9, 1 unit of token is selled by 1 SUI (MIST)
        price: u64,
        /// Inidicating whether the ido is public, if not, only the members in the whitelist can participate
        is_public: bool,
        /// The whitelist members, only those address members could participate the ido when `is_public` is set to false
        whitelists: Table<address, u8>,
    }

    public entry fun create_ido(publisher: &Publisher, name: vector<u8>, price: u64, is_public: bool, ctx: &mut TxContext) {
        assert!(package::from_package<BANK>(publisher), ENotOwner);
        assert!(price > 0, ETokenInvalidParameter);

        let ido_uid = object::new(ctx);

        // Create the ido and make it share
        let ido = TokenIdo {
            id: ido_uid,
            name: name,
            price: price,
            is_public: is_public,
            whitelists: table::new(ctx),
        };
        transfer::share_object(ido);
    }

    public entry fun set_ido_public(publisher: &Publisher, ido: &mut TokenIdo, is_public: bool)
    {
        assert!(package::from_package<BANK>(publisher), ENotOwner);
        ido.is_public = is_public;
    }

    public entry fun add_address_to_ido(ido: &mut TokenIdo, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        if (table::contains(&ido.whitelists, sender) == false) {
            table::add(&mut ido.whitelists, sender, 1);
        };

        event::emit(AddTokenIdoWhitelistEvent {
            ido_id: object::uid_to_inner(&ido.id)
        });
    }


    public entry fun set_ido_price(publisher: &Publisher, ido: &mut TokenIdo, price:u64)
    {
        assert!(package::from_package<BANK>(publisher), ENotOwner);
        ido.price = price;
    }

    public entry fun buy_token_from_ido_listed(ido: &mut TokenIdo, bank: &mut Bank, in_suis: vector<Coin<SUI>>, in_amount: u64, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        assert!(token_ido_is_public_or_has_whitelist_address(ido, sender) == true, ETokenIdoCannotBuyPermissionDenied);
        buy_token_from_ido(ido, bank, in_suis, in_amount, ctx);
    }

    public entry fun buy_token_from_ido_unlisted(ido: &mut TokenIdo, bank: &mut Bank, in_suis: vector<Coin<SUI>>, in_amount: u64, ctx: &mut TxContext)
    {
        buy_token_from_ido(ido, bank, in_suis, in_amount, ctx);
    }

    // #[allow(lint(self_transfer))]
    fun buy_token_from_ido(ido: & TokenIdo, bank: &mut Bank, in_suis: vector<Coin<SUI>>, in_amount: u64, ctx: &mut TxContext)
    {
        // assert!(token_ido_is_public_or_has_whitelist_address(ido, sender) == true, ETokenIdoCannotBuyPermissionDenied);

        // Get the in balance and out balance
        let in_balance = coin::into_balance(
            utils::merge_coins_to_amount_and_transfer_back_rest(in_suis, in_amount, ctx)
        );

        balance::join(&mut bank.SUI, in_balance);
        
        let out_amount : u64 = in_amount / ido.price;
        // debug::print(& out_amount);
        assert!(balance::value(& bank.HUSKI) >= out_amount, EInvalidNumber);
        // Transfer
        let out_balance = balance::split(&mut bank.HUSKI, out_amount);
        let out_coin = coin::from_balance(out_balance, ctx);
        
        transfer::public_transfer(out_coin, tx_context::sender(ctx));

        // Emit event
        event::emit(BuyTokenIdoTokenEvent {
            ido_id: object::uid_to_inner(&ido.id),
            in_amount: in_amount,
            out_amount: out_amount
        });
    }
    /// Check whether the token ido has the whitelist address
    fun token_ido_is_public_or_has_whitelist_address(x: &TokenIdo, addr: address): bool {
        if (x.is_public) { true } else { table::contains(&x.whitelists, addr) }
    }

    // /// Check whether the token ido has the whitelist address
    // fun is_listed(x: &TokenIdo, addr: address): bool {
    //     // if (x.is_public) { true } else { table::contains(&x.whitelists, addr) }
    //     table::contains(&x.whitelists, addr) 
    // }

    // /// Check whether the token ido has the whitelist address
    // fun token_ido_is_public(x: &TokenIdo): bool {
    //     x.is_public 
    // }


    /// Cannot not buy ido due to is not public and you are not in the whitelist
    const ETokenAirdropCannotBuyPermissionDenied: u64 = 144005;

    struct AddTokenAirdropWhitelistEvent has copy, drop {
        /// The id of the airdrop
        airdrop_id: ID,
    }

    struct Airdrop has key {
        /// The id of the token airdrop event
        id: UID,
        /// The name of the airdrop event
        name: vector<u8>,

        amount_listed: u64,
        amount_unlisted: u64,
        /// The whitelist members, only those address members could participate the airdrop when `is_public` is set to false
        whitelists: Table<address, u8>,
        blacklists: Table<address, u8>,
    }

    public entry fun create_airdrop(publisher: &Publisher, name: vector<u8>, amount_listed: u64, amount_unlisted: u64, ctx: &mut TxContext) {

        assert!(package::from_package<BANK>(publisher), ENotOwner);
        let airdrop_uid = object::new(ctx);

        // Create the airdrop and make it share
        let airdrop = Airdrop {
            id: airdrop_uid,
            name: name,
            amount_listed: amount_listed,
            amount_unlisted: amount_unlisted,
            whitelists: table::new(ctx),
            blacklists: table::new(ctx),
        };
        transfer::share_object(airdrop);
    }

    //TODO
    public entry fun add_address_to_airdrop(airdrop: &mut Airdrop, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        if (table::contains(&airdrop.whitelists, sender) == false) {
            table::add(&mut airdrop.whitelists, sender, 1);
        };

        event::emit(AddTokenAirdropWhitelistEvent {
            airdrop_id: object::uid_to_inner(&airdrop.id)
        });
    }

    //if listed
    public entry fun claim_airdrop_listed(airdrop: &mut Airdrop, bank: &mut Bank, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        assert!(token_airdrop_is_public_or_has_whitelist_address(airdrop, sender) == true, ETokenAirdropCannotBuyPermissionDenied);
        claim_airdrop(bank, airdrop.amount_listed, ctx);
        //remove address from table
        table::remove(&mut airdrop.whitelists, sender);
    }
    //
    public entry fun claim_airdrop_unlisted(airdrop: &mut Airdrop, bank: &mut Bank, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        assert!(token_airdrop_is_public_or_has_blacklist_address(airdrop, sender) == false, ETokenAirdropCannotBuyPermissionDenied);
        claim_airdrop(bank, airdrop.amount_unlisted, ctx);
        table::add(&mut airdrop.blacklists, sender,1);
    }

    // #[allow(lint(self_transfer))]
    fun claim_airdrop( bank: &mut Bank, out_amount: u64, ctx: &mut TxContext)
    {
        let sender = tx_context::sender(ctx);
        // assert!(token_airdrop_is_public_or_has_whitelist_address(airdrop, sender) == true, ETokenAirdropCannotBuyPermissionDenied);

        let out_balance = balance::split(&mut bank.HUSKI, out_amount);
        let out_coin = coin::from_balance(out_balance, ctx);

        // Transfer
        transfer::public_transfer(out_coin, sender);
    }

    /// Check whether the token airdrop has the whitelist address
    fun token_airdrop_is_public_or_has_whitelist_address(x: &Airdrop, addr: address): bool {
        table::contains(&x.whitelists, addr)
    }
    /// Check whether the token airdrop has the blacklist address
    fun token_airdrop_is_public_or_has_blacklist_address(x: &Airdrop, addr: address): bool {
        table::contains(&x.blacklists, addr)
    }

}
