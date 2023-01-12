// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract marketPlace {
    //    enum state to check status of the NFT
    // enum State{
    //     Active,
    //     Cancel,
    //     Sold,
    //     End
    // }
    //  structure to store info of listed NFT
    struct list {
        // State _status;
        uint256 id;
        uint256 price;
        address token_address;
        address seller;
        address erc20Tkn;
        bool list;
    }

    struct auctionier {
        uint256 id;
        uint256 price;
        address token_address;
        address Erc20;
        address seller;
        uint256 startTime;
        uint256 endTime;
        uint highestPayableBid;
        // uint increment;
        address highestBidder;
        bool aucStart;
        bool aucCanceled;
    }
    // events

    event Listed(
        // State _status,
        uint256 id,
        uint256 price,
        address token_address,
        address seller,
        bool list
    );

    event Canceled(
        // State _status,
        uint256 id,
        bool list
    );

    event End(
        // State _status,
        uint256 id,
        bool list
    );

    event Sold(
        // State _status,
        uint256 id,
        bool list
    );
    // Mapping to store listed nft data on uint type key value

    mapping(uint256 => list) public listingMap;
    mapping(uint256 => auctionier) public aucInfo;

    // list[] public listArray;

    // uint256 private _listingId = 1;
    // address payable auctionier;
    // uint public startTime;
    // uint public endTime;

    // aucState public _aucState;

    // uint public highestBid;
    // uint increment;

    // mapping (address => uint) public allBids;
    // list function to list nfts

    function listNft(
        address _token,
        address _erc20,
        uint256 _id,
        uint256 _price
    ) public {
        require(aucInfo[_id].aucStart == false, "auction is started");
        require(listingMap[_id].list == false);
        IERC721(_token).transferFrom(msg.sender, address(this), _id);
        // listingMap[_id]._status = State.Active;
        listingMap[_id].id = _id;
        listingMap[_id].price = _price * 1**1;
        listingMap[_id].token_address = _token;
        listingMap[_id].seller = msg.sender;
        listingMap[_id].erc20Tkn = _erc20;
        listingMap[_id].list = true;
        // _listingId ++;

        emit Listed(_id, _price, _token, msg.sender, true);
    }

    function canceListorAuction(uint256 _id) public returns (string memory) {
        if (listingMap[_id].list == true) {
            // require(listingMap[_id]._status == State.Active);
            require(msg.sender == listingMap[_id].seller);

            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            listingMap[_id].list = false;

            emit Canceled(_id, false);
        }

        if (aucInfo[_id].aucStart == true) {
            require(
                msg.sender == aucInfo[_id].seller,
                "You are not the seller"
            );
            // require(aucInfo[_id].aucStart == true,"auction is not started yet");
            require(
                aucInfo[_id].aucCanceled == false,
                "auction is already cancelled"
            );
            IERC721(aucInfo[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                aucInfo[_id].id
            );
            aucInfo[_id].startTime = 0;
            aucInfo[_id].endTime = 0;
            aucInfo[_id].aucCanceled = true;
            aucInfo[_id].aucStart = false;
        } else {
            return "First list or auctionate your token";
        }
    }

    function buyNft(uint256 _id, uint256 _price) public payable {
        require(listingMap[_id].list == true, "Listing is not active yet");
        require(
            msg.sender != listingMap[_id].seller,
            "seller can't buy the Nft"
        );
        if (listingMap[_id].erc20Tkn != address(0)) {
            require(
                _price >= listingMap[_id].price,
                "your price is not correct"
            );

            IERC20(listingMap[_id].erc20Tkn).transferFrom(
                msg.sender,
                listingMap[_id].seller,
                _price
            );
            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            // payable(listingMap[_id].seller).transfer(msg.value);

            listingMap[_id].list = false;

            emit Sold(_id, false);
        } else {
            _price = msg.value;
            require(
                _price >= listingMap[_id].price,
                "your price is not correct"
            );

            // IERC20(listingMap[_id].erc20Tkn).transferFrom(msg.sender,listingMap[_id].seller,_price);
            IERC721(listingMap[_id].token_address).transferFrom(
                address(this),
                msg.sender,
                listingMap[_id].id
            );

            // (bool, bytes memory) = msg.sender.call{value : _price}("");
            payable(listingMap[_id].seller).transfer(_price);

            listingMap[_id].list = false;

            emit Sold(_id, false);
        }
    }

    function auction(
        address _token,
        address erc20,
        uint256 _id,
        uint256 _initPrice,
        uint256 _duration
    ) public {
        // require(listingMap[_id]._status == State.Active,"Listing is not active");
        // require(msg.sender == listingMap[_id].seller,"You are not the seller");
        // require(listingMap[_id]._status != State.Active,"You already listed your NFT");
        require(listingMap[_id].list == false, "you already listed your NFT");
        require(aucInfo[_id].aucStart == false);
        IERC721(_token).transferFrom(msg.sender, address(this), _id);
        aucInfo[_id].id = _id;
        aucInfo[_id].price = _initPrice;
        aucInfo[_id].token_address = _token;
        aucInfo[_id].Erc20 = erc20;
        aucInfo[_id].seller = msg.sender;
        aucInfo[_id].startTime = block.timestamp;
        aucInfo[_id].endTime = block.timestamp + _duration;
        aucInfo[_id].aucCanceled = false;
        aucInfo[_id].aucStart = true;
    }

    // function cancelAuction(uint256 _id) public {
    //     // require(listingMap[_id]._status == State.Active,"Listing is not active");
    //     require(msg.sender == aucInfo[_id].seller,"You are not the seller");
    //     require(aucInfo[_id].aucStart == true,"auction is not started yet");
    //     require(aucInfo[_id].aucCanceled == false,"auction is already cancelled");
    //     aucInfo[_listingId].startTime = 0;
    //     aucInfo[_listingId].endTime = 0;
    //     aucInfo[_listingId].aucCanceled = true;
    //     aucInfo[_listingId].aucStart = false;
    // }

    function bidding(uint256 _id, uint256 _price) public payable {
        require(aucInfo[_id].aucStart == true, "Auction is not started");
        require(
            aucInfo[_id].aucCanceled == false,
            "auction is already cancelled"
        );
        require(msg.sender != aucInfo[_id].seller, "you can't bid");

        require(_price > aucInfo[_id].price, "Enter correct price");
        require(block.timestamp < aucInfo[_id].endTime, "auction is ended");

        IERC20 tkn = IERC20(aucInfo[_id].Erc20);
        if (aucInfo[_id].Erc20 != address(0)) {
            require(_price > aucInfo[_id].highestPayableBid, "Your bid is low");

            uint _currentBid = _price;

            // tkn.transferFrom(msg.sender, address(this), _currentBid);

            if (
                aucInfo[_id].highestBidder != address(0) &&
                _currentBid > aucInfo[_id].highestPayableBid
            ) {
                // require(_currentBid > highestPayableBid);
                // _currentBid =  msg.value;
                tkn.transfer(
                    aucInfo[_id].highestBidder,
                    aucInfo[_id].highestPayableBid
                );
                // allBids[highestBidder] = highestPayableBid;
            }
            aucInfo[_id].highestPayableBid = _currentBid;
            aucInfo[_id].highestBidder = msg.sender;
            tkn.transferFrom(
                aucInfo[_id].highestBidder,
                address(this),
                aucInfo[_id].highestPayableBid
            );
        } else {
            // require(aucInfo[_id].aucStart == true,"Auction is not started");
            // require(aucInfo[_id].aucCanceled == false,"auction is already cancelled");
            // require(msg.sender != aucInfo[_id].seller,"you can't bid");

            // require(msg.value > aucInfo[_id].price,"Enter correct price");
            // require(block.timestamp < aucInfo[_id].endTime,"auction is ended");
            // require(msg.value > aucInfo[_id].highestPayableBid,"Your bid is low");
            // require(highestBidder != address(0));
            require(_price > aucInfo[_id].highestPayableBid, "Your bid is low");
            uint _currentBid = msg.value;

            if (
                aucInfo[_id].highestBidder != address(0) &&
                _currentBid > aucInfo[_id].highestPayableBid
            ) {
                // require(_currentBid > highestPayableBid);
                // _currentBid =  msg.value;
                payable(aucInfo[_id].highestBidder).transfer(
                    aucInfo[_id].highestPayableBid
                );
                // allBids[highestBidder] = highestPayableBid;
            }
            aucInfo[_id].highestPayableBid = _currentBid;
            aucInfo[_id].highestBidder = msg.sender;
        }
        // highestPayableBid = msg.value;
        // highestBidder = msg.sender;
    }

    function finalizeAuction(uint256 _id) public payable {
        require(
            aucInfo[_id].aucCanceled == false ||
                block.timestamp > aucInfo[_id].endTime,
            "Auction is not started"
        );
        require(
            msg.sender == aucInfo[_id].highestBidder ||
                msg.sender == aucInfo[_id].seller,
            "error"
        );

        // address payable person;
        // uint256 value;
        IERC721(aucInfo[_id].token_address).transferFrom(
            address(this),
            aucInfo[_id].highestBidder,
            aucInfo[_id].id
        );

        aucInfo[_id].aucStart = false;
    }
}