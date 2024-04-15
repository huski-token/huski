#[test_only]
module huski::test {
    use sui::sui::SUI;
    use sui::coin::{Coin, TreasuryCap, mint_for_testing as mint};
    use sui::test_scenario::{Self as test, Scenario, next_tx, ctx};
    use huski::bank::{Self, Bank, TokenIdo};
    use huski::token::{Self, TOKEN};
    use sui::package::{Publisher};
    use huski::drand_lib;
    // use huski::sbank::{Self, SBank, SToken};
    use std::vector;
    use std::debug;

    const ONE_SUI:u64 = 1000000000;
    const ONE_TOKEN:u64 = 1;
    //18446744073709551615
    const TOKEN_MAX_SUPPLY: u64 = 4200000000;
    
    #[test] fun test_init_bank() {
        let scenario = scenario();
        test_init_bank_(&mut scenario);
        test::end(scenario);
    }
    #[test] fun test_init_token() {
        let scenario = scenario();
        test_init_token_(&mut scenario);
        test::end(scenario);
    }
    #[test] fun test_add_liquidity() {
        let scenario = scenario();
        test_add_liquidity_(&mut scenario);
        test::end(scenario);
    }
    #[test] fun test_remove_liquidity() {
        let scenario = scenario();
        test_remove_liquidity_(&mut scenario);
        test::end(scenario);
    }
    #[test] fun test_rand() {
        drand_lib::test_rand();
        // debug::print(&rand);
    }
  
    fun test_init_bank_(test: &mut Scenario) {
        let (_, owner) = people();
        next_tx(test, owner);
        {
            bank::test_init(ctx(test));
        };
        next_tx(test, owner);
        {
            let bank = test::take_shared<Bank>(test);

            // let bank_mut = &mut bank;
            // debug::print(bank_mut);
            test::return_shared(bank);
        };
    }

    fun test_init_token_(test: &mut Scenario) {
        let (_, owner) = people();
        next_tx(test, owner);
        {
            token::test_init(ctx(test));
        };
        next_tx(test, owner);
        {
            let treasury_cap = test::take_from_address<TreasuryCap<TOKEN>>(test,owner);
            let treasury_cap_mut = &mut treasury_cap;
            token::mint(
                treasury_cap_mut,
                ONE_TOKEN * TOKEN_MAX_SUPPLY,
                owner,
                ctx(test)
            );

            // debug::print(treasury_cap_mut);
            test::return_to_address(owner,treasury_cap);
        };
    }

    fun test_add_liquidity_(test: &mut Scenario) {
        test_init_bank_(test);
        test_init_token_(test);
        let (_, owner) = people();
        next_tx(test, owner);
        let bank = test::take_shared<Bank>(test);
        let publisher = test::take_from_address<Publisher>(test,owner);
        bank::add_sui_to_bank(
            &mut bank,
            mint<SUI>(ONE_SUI, ctx(test))
        );
        
        let token = test::take_from_address<Coin<TOKEN>>(test,owner);
        // debug::print(& token);
        bank::add_huski_to_bank(
            &mut bank,
            token
        );
        
        // debug::print(& bank);
        test::return_shared(bank);
        test::return_to_address(owner, publisher);
    }

    fun test_remove_liquidity_(test: &mut Scenario) {
        test_add_liquidity_(test);
        let (_, owner) = people();
        next_tx(test, owner);
        let bank = test::take_shared<Bank>(test);
        let publisher = test::take_from_address<Publisher>(test,owner);
        // debug::print( & publisher);

        bank::remove_sui_from_bank( 
            &publisher,
            &mut bank,
            ONE_SUI,
            ctx(test)
        );
        bank::remove_huski_from_bank( 
            &publisher,
            &mut bank,
            ONE_TOKEN,
            ctx(test)
        );

        // debug::print( & bank);
        test::return_shared(bank);
        test::return_to_address(owner, publisher);
    }

    // #[test] fun test_ido() {
    //     let scenario = scenario();
    //     test_ido_(&mut scenario);
    //     test::end(scenario);
    // }

    // fun test_ido_(test: &mut Scenario)
    // {
    //     test_add_liquidity_(test);
    //     let (_, owner) = people();
    //     next_tx(test, owner);
    //     let publisher = test::take_from_address<Publisher>(test,owner);
    //     bank::create_ido(& publisher,b"listed",1000000,false,ctx(test));
    //     next_tx(test, owner);
    //     let ido = test::take_shared<TokenIdo>(test);

    //     // let is_listed = bank::token_ido_is_public_or_has_whitelist_address(& ido,owner);

    //     bank::add_address_to_ido(&mut ido,ctx(test));

    //     // let is_listed = bank::token_ido_is_public_or_has_whitelist_address(& ido,owner);

    //     let sui=mint<SUI>(ONE_SUI, ctx(test));
    //     let sui_vec = vector::empty<Coin<SUI>>();
    //     vector::push_back<Coin<SUI>>(&mut sui_vec,sui);
    //     let sui=mint<SUI>(ONE_SUI, ctx(test));
    //     vector::push_back<Coin<SUI>>(&mut sui_vec,sui);

    //     let bank = test::take_shared<Bank>(test);

    //     bank::buy_token_from_ido_listed(&mut ido,&mut bank,sui_vec,ONE_SUI,ctx(test));
    //     next_tx(test, owner);

    //     let token = test::take_from_address<Coin<TOKEN>>(test,owner);
    //     // debug::print(& token);

    //     test::return_shared(ido);
    //     test::return_shared(bank);
    //     test::return_to_address(owner, token);
    //     test::return_to_address(owner, publisher);
    // }

    // utilities
    fun scenario(): Scenario { test::begin(@0x1) }
    fun people(): (address, address) { (@0xBEEF, @0x1337) }

}
