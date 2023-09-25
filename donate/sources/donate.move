module donate::donate {
    use std::signer;

    use aptos_framework::account;
    use aptos_framework::coin::{Self, transfer};
    use aptos_framework::event::{Self, EventHandle};
    use aptos_framework::timestamp;

    const ENotEoughtCoinToDonate: u64 = 1;

    struct DonateAccount has key {
        donator: address,
        donate_count: u64,
        donate_event: EventHandle<DonateEvent>
    }

    struct DonateEvent has store, drop {
        donator: address,
        receiver: address,
        amount: u64,
        timestamp: u64
    }

    public fun register(donator: &signer) {
        move_to(donator, DonateAccount {
            donator: signer::address_of(donator),
            donate_count: 0,
            donate_event: account::new_event_handle<DonateEvent>(donator)
        });
    }

    public fun update_donate_count(donate_account: &mut DonateAccount) {
        let donate_count_mut = &mut donate_account.donate_count;
        *donate_count_mut = donate_account.donate_count + 1;
    }

    public fun emit_donate_event(donator: &signer, amount: u64, receiver: address, donate_account: &mut DonateAccount) {
        event::emit_event<DonateEvent>(
            &mut donate_account.donate_event,
            DonateEvent(
                signer::address_of(donator),
                receiver,
                amount,
                timestamp::now_microseconds()
            ));
    }

    public entry fun donate_to_user<CoinType>(donator: &signer, amount: u64, receiver: address) acquires DonateAccount {

        let addr = signer::address_of(donator);
        if (!exists<DonateAccount>(addr)) {
            register(donator);
        };
        assert!(coin::balance<CoinType>(addr) >= amount, ENotEoughtCoinToDonate);
        transfer<CoinType>(donator, receiver, amount);
        let donate_account = borrow_global_mut<DonateAccount>(addr);
        update_donate_count(donate_account);
        emit_donate_event(donator, amount, receiver, donate_account);
    }
}
