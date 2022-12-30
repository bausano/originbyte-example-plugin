module foo_royalty::plugin {
    use sui::balance;
    use sui::tx_context::{TxContext};

    use nft_protocol::collection::{Collection};
    use nft_protocol::royalties::{Self, TradePayment};
    use nft_protocol::royalty;

    use foo::foo::{Self, FOO};

    struct Witness has drop {}

    public entry fun collect_royalty<FT>(
        payment: &mut TradePayment<FOO, FT>,
        collection: &mut Collection<FOO>,
        ctx: &mut TxContext,
    ) {
        let b = royalties::balance_mut(
            foo::witness_for_plugin(Witness {}, collection),
            payment,
        );

        let domain = royalty::royalty_domain(collection);
        let royalty_owed =
            royalty::calculate_proportional_royalty(domain, balance::value(b));

        royalty::collect_royalty(collection, b, royalty_owed);
        royalties::transfer_remaining_to_beneficiary(
            foo::witness_for_plugin(Witness {}, collection),
            payment,
            ctx,
        );
    }
}
