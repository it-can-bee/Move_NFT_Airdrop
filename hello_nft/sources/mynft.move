//mycoin Move
module hello_nft::mynft {
    use mgo::url::{Self, Url};
    use mgo::transfer;
    use mgo::object::{Self, UID};
    use mgo::tx_context::{Self, TxContext};
    use mgo::package::{Self};
    use std::string::{Self,String};
    use mgo::display::{Self};
    use std::vector;

    #[allow(unused_const)]
    const ErrorByAddressAndAmountsLengthMismatch: u64 = 1;
    const ErrorInsufficientAllowanceForAirdrop: u64 = 2;


    struct NFT has key, store{
        id: UID,
        name: String,
        description: String,
        creator: address,
        url: Url,
    }
    struct MYNFT has drop{}

    struct NFTHolderCap has key, store {
        id: UID,
        nfts: vector<NFT>,
        total_supply: u64,
    }
    // 增加对浏览器对象显示的支持
    #[allow(lint(share_owned))]
    fun init (otw: MYNFT, ctx: &mut TxContext){
        let publisher = package::claim(otw, ctx);
        let keys = vector[
            string::utf8(b"name"),
            string::utf8(b"image_url"),
            string::utf8(b"description"),
            string::utf8(b"creator"),
        ];

        let values = vector[
            string::utf8(b"{name}"),
            string::utf8(b"{url}"),
            string::utf8(b"{description}"),
            string::utf8(b"{creator}")
        ];
        //触发事件event
        let display = display::new_with_fields<NFT>(
            &publisher,
            keys,
            values,
            ctx,
        );

        let holder = NFTHolderCap {
            id: object::new(ctx),
            nfts: vector::empty(),
            total_supply: 0,
        };

        display::update_version(&mut display);
        transfer::public_share_object(display);
        transfer::public_transfer(holder, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx))
    }
    // 将“nft”转移到address
    public entry fun transfer(
        nft: NFT, recipient: address, _: &mut TxContext
    ) {
        transfer::public_transfer(nft, recipient)
    }
    // 铸造nft
    public entry fun mint(
        nftcap_holder: &mut NFTHolderCap,
        name: String,
        description: String,
        url:String,
        amount: u64,
        ctx: &mut TxContext,
    ) {
        let nft = NFT{
            id: object::new(ctx),
            name: name,
            description: description,
            creator: tx_context::sender(ctx),
            url: url::new_unsafe(string::to_ascii(url)),
        };
        nftcap_holder.total_supply = nftcap_holder.total_supply + amount;
        vector::push_back(&mut nftcap_holder.nfts, nft);
        let index = vector::length(&nftcap_holder.nfts) - 1;
        let nft_to_transfer = vector::remove(&mut nftcap_holder.nfts, index);
        transfer::public_transfer(nft_to_transfer, tx_context::sender(ctx));
    }

    //计算求和
    public fun getSum(amounts: vector<u64>): u64 {
        let airdropNum = 0u64;
        let len = vector::length(&amounts);
        let i = 0;
        while (i < len) {
            let amount = *vector::borrow(&amounts, i);
            airdropNum = airdropNum + amount;
            i = i + 1;
        };
        airdropNum
    }

    public entry fun airdrop(
        nftcap_holder: &mut NFTHolderCap,
        amounts: vector<u64>,
        addresses: vector<address>,
        _: &mut TxContext,
    ) {
        assert!(vector::length(&addresses) == vector::length(&amounts), ErrorByAddressAndAmountsLengthMismatch);
        let amountSum = getSum(amounts);
        assert!(nftcap_holder.total_supply >= amountSum, ErrorInsufficientAllowanceForAirdrop);

        let length = vector::length(&addresses);
        let index = 0;
        while(index < length) {
            let recipient = *vector::borrow(&addresses, index);
            let nft_to_transfer = vector::remove(&mut nftcap_holder.nfts, index);
            transfer::public_transfer(nft_to_transfer, recipient);
            let amounts = *vector::borrow(&amounts, index);

            nftcap_holder.total_supply = nftcap_holder.total_supply - amounts;
            index = index + 1;
        }
    }
    //批量mint
    public entry fun batch_mint(
        nftcap_holder: &mut NFTHolderCap,
        names: vector<String>,
        descriptions: vector<String>,
        urls: vector<String>,
        amounts: vector<u64>,
        ctx: &mut TxContext,
    ) {
        let length = vector::length(&names);
        let key: bool = (vector::length(&descriptions) == length) && (vector::length(&urls) == length);
        assert!(key, ErrorByAddressAndAmountsLengthMismatch);
        let i = 0;
        while (i < length) {
            let new_name = vector::borrow(&names, i);
            let new_description = vector::borrow(&descriptions, i);
            let new_url = vector::borrow(&urls, i);
            let amount = vector::borrow(&amounts, i);
            mint(nftcap_holder, *new_name, *new_description, *new_url, *amount, ctx);
            nftcap_holder.total_supply = nftcap_holder.total_supply + *amount;
            i = i + 1;
        }
    }

    /* ===== Public view functions ===== */
    // 更新name
    public entry fun update_name(
        nft: &mut NFT,
        new_name: String,
        _: &mut TxContext
    ) {
        nft.name = new_name;
    }

    // 更新创建者
    public entry fun update_creator(
        nft: &mut NFT,
        new_creator: address,
        _: &mut TxContext
    ) {
        nft.creator = new_creator;
    }

    // 更新url
    public entry fun update_Url(
        nft: &mut NFT,
        new_url: String,
        _: &mut TxContext
    ) {
        let new_url_string = url::new_unsafe(string::to_ascii(new_url));
        nft.url = new_url_string;
    }

    // 更新description
    public entry fun update_description(
        nft: &mut NFT,
        new_description: String,
        _: &mut TxContext
    ) {
        nft.description = new_description;
    }

    // 删除“nft”
    public entry fun burn(nft: NFT, _: &mut TxContext) {
        let NFT { id, name: _, description: _, url: _ ,creator:_} = nft;
        object::delete(id)
    }

    /* ===== Getter functions ===== */
    /// 获取NFT的名称
    public fun get_name(nft: &NFT): &string::String {
        &nft.name
    }

    /// 获取NFT的介绍
    public fun get_description(nft: &NFT): &string::String {
        &nft.description
    }

    /// 获取NFT的链接
    public fun get_url(nft: &NFT): &Url {
        &nft.url
    }

    /// 获取NFT的创建者
    public fun get_creator(nft: &NFT): &address {
        &nft.creator
    }

}