module donate::donate {
    use std::signer;
    use std::string::String;

    use aptos_std::type_info;
    use aptos_framework::account;
    use aptos_framework::coin::{Self, transfer};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    const ENotEoughtCoinToDonate: u64 = 1;

    /*
    struct DonateInfo has store, drop {
        receiver: address,
        coin_type: String,
        amount: u64,
        timestamp: u64,
        message: String
    }

    struct DonatorList has key {
        donator_list: vector<address>
    }*/

    struct DonateStore has key {
        donate_count: u64,
        donate_event: EventHandle<DonateEvent>
    }

    struct DonateEvent has store, drop {
        donator: address,
        receiver: address,
        coin_type: String,
        amount: u64,
        timestamp: u64,
        message: String,
        cid: String
    }
    /*
    fun init_module(contract_address: &signer) {
        let donator_list = DonatorList {
            donator_list: vector::empty<address>()
        };
        move_to(contract_address, donator_list);
    }*/

    public fun register(donator: &signer) {
        move_to(donator, DonateStore {
            donate_count: 0,
            donate_event: account::new_event_handle<DonateEvent>(donator)
        });
    }

    /*
    public fun get_donator_list(account: &signer): &vector<address> acquires DonatorList {
        &borrow_global<DonatorList>(@donate).donator_list
    }
    */

    public fun update_donate_store<CoinType>(donate_store: &mut DonateStore) {
        let donate_count_ref = donate_store.donate_count;
        let donate_count_mut = &mut donate_store.donate_count;
        *donate_count_mut = donate_count_ref + 1;
    }

    public fun emit_donate_event<CoinType>(donate_store: &mut DonateStore,
                                           donator: &signer,
                                           amount: u64,
                                           receiver: address,
                                           timestamp: u64,
                                           message: String,
                                           cid: String) {
        event::emit_event<DonateEvent>(
            &mut donate_store.donate_event,
            DonateEvent {
                donator: signer::address_of(donator),
                receiver,
                coin_type: type_info::type_name<CoinType>(),
                amount,
                timestamp,
                message,
                cid
            }
        );
    }

    public entry fun donate_to_user<CoinType>(donator: &signer,
                                              cid: String,
                                              amount: u64,
                                              receiver: address,
                                              message: String) acquires DonateStore {
        let addr = signer::address_of(donator);
        if (!exists<DonateStore>(addr)) {
            register(donator);
        };
        assert!(coin::balance<CoinType>(addr) >= amount, ENotEoughtCoinToDonate);
        let tstamp = timestamp::now_microseconds();
        transfer<CoinType>(donator, receiver, amount);
        let donate_store = borrow_global_mut<DonateStore>(addr);
        update_donate_store<CoinType>(donate_store);
        emit_donate_event<CoinType>(donate_store, donator, amount, receiver, tstamp, message, cid);
    }
}
