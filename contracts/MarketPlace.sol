// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MarketPlace {
    struct TokenDetails {
        address addOfContract;
        bool isERC1155;
        uint256 tokenId;
        uint256 noOfAssets;
        uint256 price;
        address addOfERC20;
        string payment;
        address owner;
    }

    mapping(uint256 => bool) private isRegistered;
    mapping(uint256 => TokenDetails) private registeredToken;
    mapping(uint256 => address) registeredTokenOwner;

    TokenDetails private tokenDetail;

    event TokenRegistered(uint256 _tokenId, address owner);
    event buyToken(uint256 _tokenId, address buyer);

    /// It is for ERC1155 token
    function registerERC1155Token(
        address _addOf1155Contract,
        uint256 _tokenId,
        uint256 _noOfAsset,
        uint256 _price,
        address _addOfERC20,
        string calldata _payment
    ) public returns (bool) {
        IERC1155 token1155 = IERC1155(tokenDetail.addOfContract);
        require(
            token1155.balanceOf(_addOf1155Contract, _tokenId) >= _noOfAsset,
            "Not having required number of assets"
        );
        tokenDetail.addOfContract = _addOf1155Contract;
        tokenDetail.tokenId = _tokenId;
        tokenDetail.noOfAssets = _noOfAsset;
        tokenDetail.price = _price;
        tokenDetail.addOfERC20 = _addOfERC20;
        tokenDetail.isERC1155 = true;
        tokenDetail.owner = msg.sender;

        tokenDetail.payment = _payment;

        isRegistered[_tokenId] = true;

        token1155.setApprovalForAll(address(this), true);

        registeredToken[_tokenId] = tokenDetail;

        emit TokenRegistered(_tokenId, _addOf1155Contract);
        return true;
    }

    function registerERC721Token(
        address _addOfContract,
        uint256 _tokenId,
        uint256 _noOfAsset,
        uint256 _price,
        address _addOfERC20,
        string calldata _payment
    ) public returns (bool) {
        IERC721 token721 = IERC721(tokenDetail.addOfContract);
        require(
            token721.balanceOf(_addOfContract) >= _noOfAsset,
            "Not having required number of assets"
        );

        tokenDetail.addOfContract = _addOfContract;
        tokenDetail.tokenId = _tokenId;
        tokenDetail.noOfAssets = _noOfAsset;
        tokenDetail.price = _price;
        tokenDetail.addOfERC20 = _addOfERC20;
        tokenDetail.isERC1155 = false;
        tokenDetail.owner = msg.sender;

        /// _payment can be WETH or ETH
        tokenDetail.payment = _payment;

        isRegistered[_tokenId] = true;

        token721.approve(address(this), _tokenId);
        registeredToken[_tokenId] = tokenDetail;

        emit TokenRegistered(_tokenId, msg.sender);
        return true;
    }

    // @params
    ///  payToken address of token from which payment will be done
    ///  _tokenid  which specific token buyer wants to buy
    ///  _noOfTokens  How many number of token buyer want to buy
    ///  _price  How much price buyer is ready to give for all tokens he wants to buy
    function buy(
        address _token20,
        uint256 _tokenid,
        uint256 _noOfAssets,
        uint256 _price
    ) public payable {
        require(isRegistered[_tokenid], "token is not registered");
        require(_noOfAssets <= registeredToken[_tokenid].noOfAssets);
        uint256 pricePerToken = _noOfAssets / _price;
        require(
            registeredToken[_tokenid].price == pricePerToken,
            "Not a acceptable price"
        );

        IERC20 token20;
        if (_token20 != address(0)) {
            token20 = IERC20(_token20);
        } else {
            // Mumbai WETH address
            token20 = IERC20(0xA6FA4fB5f76172d178d61B04b0ecd319C5d1C0aa);
        }
        token20.approve(address(this), _price);

        if (registeredToken[_tokenid].isERC1155) {
            address seller = registeredToken[_tokenid].addOfContract;
            IERC1155 sellerToken = IERC1155(seller);
            sellerToken.safeTransferFrom(
                seller,
                msg.sender,
                _tokenid,
                _noOfAssets,
                ""
            );
            token20.transferFrom(msg.sender, seller, _price);
        } else {
            address seller = registeredToken[_tokenid].owner;
            IERC721 sellerToken = IERC721(seller);
            sellerToken.safeTransferFrom(seller, msg.sender, _tokenid);
        }

        if (registeredToken[_tokenid].noOfAssets - _noOfAssets == 0) {
            isRegistered[_tokenid] = false;
        } else {
            registeredToken[_tokenid].noOfAssets -= _noOfAssets;
        }

        // A fee of 0.55% will be reserved for the marketplace owner which he can withdraw later
        uint256 fee = (_price * uint256(11)) / uint256(20);
        token20.approve(address(this), fee);

        emit buyToken(_tokenid, msg.sender);
    }
}
