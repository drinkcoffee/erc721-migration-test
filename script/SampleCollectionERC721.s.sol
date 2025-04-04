// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SampleCollectionERC721} from "../src/SampleCollectionERC721.sol";

contract SampleCollectionERC721Script is Script {
    address constant MAINNET_OPERATOR_ALLOWLIST = 0x5F5EBa8133f68ea22D712b0926e2803E78D89221;
    address constant TESTNET_OPERATOR_ALLOWLIST = 0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE;

    SampleCollectionERC721 public token;

    function setUp() public {}

    function deploy(bool _deployToMainnet) public {
        string memory baseURI = "https://drinkcoffee.github.io/projects/nfts/";
        string memory contractURI = "https://drinkcoffee.github.io/projects/nfts/sample-collection.json";
        string memory name = "ERC721 Sample Collection";
        string memory symbol = "SC7";
        uint96 feeNumerator = 200; // 2%

        address operatorAllolist = _deployToMainnet ? MAINNET_OPERATOR_ALLOWLIST : TESTNET_OPERATOR_ALLOWLIST;

        address owner = 0xE0069DDcAd199C781D54C0fc3269c94cE90364E2;
        address minter = owner;
        address royaltyReceiver = owner;

        vm.broadcast();
        token = new SampleCollectionERC721(
            owner, minter, name, symbol, baseURI, contractURI, operatorAllolist, royaltyReceiver, feeNumerator
        );

        console.log("Deployed to: %x", address(token));
    }
}
