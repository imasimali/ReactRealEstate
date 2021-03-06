// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
//Visibilty modifiers
//1-public : anyone can call them.
//2-private: only called within a contract eg another function can call a provate func within a contract
//3-internal: inheriting contracts can also call this function but not external contracts or functions
//4-external: only external contracts/wallets can call it. not within the parent.
//mappings cannot be external
contract Blockyards{

    //EVENTS - used to ouput data externally after makings changes. 
    event ASSET_LISTED(
        string assetId,
        address seller,
        uint price,
        string metadata  
    );
    
    event ASSET_BOUGHT(
        string assetId,
        address seller,
        address buyer,
        uint price,
        string metadata
      );

    event ASSET_DELISTED(
        string assetId, 
        address seller,
        uint price,
        string metadata
    );

    address Admin;
     //ENUMS- are statuses.
    enum ListingStatus{active_0,sold_1,cancelled_2}   //options or states of the property/asset. they show as 0,1 or 2 in the blockchain, not by their actual names
    //mappings are key value pairs.
    mapping(string => ASSET) private _listings;  //maps asset Id to Asset struct. 
    

    constructor() {
       Admin = msg.sender;                  //Admin will be the contract deployer address
    }

    uint private listingId = 0;

    struct ASSET{
        ListingStatus status;       //current state of the asset i.e {active,sold,cancelled}. 
        string assetId;            //should be unique alpha numeric
        uint   price;               //in wei:  1 eth equals 1* 10^18 wei
        address owner;              // owner in possession of the asset
        string metadata;            //details about the property                
        address seller;         //store who is selling, will show 0x0000. if not selling
        //string History;                  //store asset history      
    }

    //modifiers are priveleged users of some functions
    modifier isSeller(string memory _assetId){
        ASSET memory listing = _listings[_assetId];
        //only seller or admin can delist
        require(msg.sender == listing.seller || msg.sender == Admin, "only sellers and admin have the right to delist a listed Asset");
        _;
    }

    //GETTER-FUNCTION-returns listing details acc to its assetId.
    function get_listing(string memory _assetId) public view returns(ASSET memory){
        ASSET memory listing = _listings[_assetId];
        require(keccak256(abi.encodePacked((listing.assetId))) != keccak256(abi.encodePacked((''))), "Please make sure this property is listed");
        //require(listing.status != ListingStatus.active_0, "Only properties with an active status can be shown");
        return _listings[_assetId];
    }

    //FUNCTION-lists properties-emits listed_event
    function listASSET(string memory _assetId, uint _price, string memory _metadata ) external {
        require(_price != 0, "price cannot be 0");
        //passing parameters to fill the listing struct.
        //listing here is a temporary variable of type ASSET.
        ASSET memory listing = ASSET(ListingStatus.active_0, _assetId, _price, msg.sender, _metadata, msg.sender);
        listingId++;                        //listing counter starts from 1 and increments further
        _listings[_assetId] = listing;    //stores asset at the index acc to its assetId   

        emit ASSET_LISTED(
            listing.assetId,
            listing.seller,
            listing.price,
            listing.metadata 
        );
    }

    //FUNCTION-buys assets
    function buyASSET(string memory _assetId) external payable {
        //storage means the listing variable is not temporary
        ASSET storage listing = _listings[_assetId];
        require(msg.sender != listing.seller, "seller cannot buy their own asset");
        require(listing.status == ListingStatus.active_0, "Only active properties can be bought. ");
        require(msg.value >= listing.price, "insufficient funds");
        
        payable(listing.seller).transfer(listing.price);        //payment
        listing.owner = msg.sender;                             //buyer is the owner now
        listing.status = ListingStatus.sold_1;    //status will be updated 
        listing.seller = 0x0000000000000000000000000000000000000000; //asset has no seller now

        emit ASSET_BOUGHT(
            listing.assetId,
            listing.seller,
            msg.sender,
            listing.price,
            listing.metadata 
        );
    }

    function delistASSET(string memory _assetId) external isSeller(_assetId) {

        ASSET storage listing = _listings[_assetId];
        require(listing.status == ListingStatus.active_0, "if status != active_0, then can't cancel");
        listing.status = ListingStatus.cancelled_2;     //listing status of asset set to 2nd state which is cancelled

        emit ASSET_DELISTED(
            listing.assetId,
            listing.seller,
            listing.price,
            listing.metadata 
        );
    }

}