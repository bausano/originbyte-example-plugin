module foo::foo {
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::share_object;

    use nft_protocol::collection::{Self, Collection};
    use nft_protocol::utils;
    use nft_protocol::plugins;
    use nft_protocol::multisig::{Self, Multisig};
    use nft_protocol::transfer_allowlist;

    /// One time witness is only instantiated in the init method
    struct FOO has drop {}

    /// Can be used for authorization of other actions post-creation. It is
    /// vital that this struct is not freely given to any contract, because it
    /// serves as an auth token.
    struct Witness has drop {}

    fun init(witness: FOO, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);

        let (mint_cap, collection) = collection::create<FOO>(
            &witness,
            ctx,
        );

        let col_cap = transfer_allowlist::create_collection_cap<FOO, Witness>(
            &Witness {}, ctx,
        );

        transfer::transfer(col_cap, sender);
        transfer::transfer(mint_cap, sender);
        collection::share<FOO>(collection);
    }

    public fun witness_for_plugin<PluginWitness: drop>(
        _plugin_witness: PluginWitness,
        collection: &Collection<FOO>,
    ): Witness {
        let plugins_domain = plugins::borrow_plugin_domain(collection);
        plugins::assert_has_plugin<PluginWitness>(plugins_domain);

        Witness {}
    }

    struct AddPlugin<phantom PluginWitness> has drop, store {}

    public entry fun create_multisig_to_add_plugin<PluginWitness>(
        collection: &Collection<FOO>,
        ctx: &mut TxContext,
    ) {
        let m = multisig::new(AddPlugin<PluginWitness>{}, collection, ctx);
        share_object(m);
    }

    public entry fun add_plugin<PluginWitness>(
        multisig: &mut Multisig<AddPlugin<PluginWitness>>,
        collection: &mut Collection<FOO>,
        ctx: &mut TxContext,
    ) {
        // 75% of share power is required to add a plugin
        multisig::consume_with_min_bps_share(
            utils::bps() / 100 * 75,
            collection,
            multisig,
            ctx,
        );

        let d = plugins::borrow_plugin_domain_mut(Witness{}, collection);
        plugins::add_plugin<PluginWitness>(d);
    }
}
