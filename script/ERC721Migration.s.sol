// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SampleERC721} from "../src/SampleERC721.sol";
import {SampleERC721Bootstrap} from "../src/SampleERC721Bootstrap.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "@imtbl/contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {ImmutableERC721MintByIDBootstrapV3} from
    "@imtbl/contracts/token/erc721/preset/ImmutableERC721MintByIDBootstrapV3.sol";
import {ImmutableERC721MintByIDUpgradeableV3} from
    "@imtbl/contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";
import {OperatorAllowlistUpgradeable} from "@imtbl/contracts/allowlist/OperatorAllowlistUpgradeable.sol";
import {DeployOperatorAllowlist} from "@imtbl/test/utils/DeployAllowlistProxy.sol";
import {ERC1967Proxy} from "@openzeppelin-contracts-4/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC721Upgradeable} from "@openzeppelin-contracts-upgradeable-4/token/ERC721/ERC721Upgradeable.sol";

contract ERC721MigrationScript is Script {
    address constant MAINNET_OPERATOR_ALLOWLIST = 0x5F5EBa8133f68ea22D712b0926e2803E78D89221;
    address constant TESTNET_OPERATOR_ALLOWLIST = 0x6b969FD89dE634d8DE3271EbE97734FEFfcd58eE;
    address constant OWNER = 0xE0069DDcAd199C781D54C0fc3269c94cE90364E2;

    function setUp() public {}

    function deployBootstrap(bool _deployToMainnet) public {
        string memory baseURI = "https://drinkcoffee.github.io/projects/nfts/";
        string memory contractURI = "https://drinkcoffee.github.io/projects/nfts/sample-collection.json";
        string memory name = "ERC721 Sample Collection";
        string memory symbol = "SC7";
        uint96 feeNumerator = 200; // 2%

        address operatorAllolist = _deployToMainnet ? MAINNET_OPERATOR_ALLOWLIST : TESTNET_OPERATOR_ALLOWLIST;

        address owner = OWNER;
        address minter = owner;
        address royaltyReceiver = owner;

        bytes memory initData = abi.encodeWithSelector(
            SampleERC721Bootstrap.initialize.selector,
            owner,
            minter,
            name,
            symbol,
            baseURI,
            contractURI,
            operatorAllolist,
            royaltyReceiver,
            feeNumerator
        );

        vm.startBroadcast();
        SampleERC721Bootstrap bootstrapImpl = new SampleERC721Bootstrap();
        console.log("Deployed bootstrap implementation to: %x", address(bootstrapImpl));

        ERC1967Proxy proxy = new ERC1967Proxy(address(bootstrapImpl), initData);
        console.log("Deployed proxy to: %x", address(proxy));
        vm.stopBroadcast();
    }


    function mintAndSetRoyalties(address proxy, address user1, address user2) public {
        address owner = OWNER;
        address royaltyReceiver = owner;

        IImmutableERC721 erc721 = IImmutableERC721(proxy);

        // Mint some NFTs
        IImmutableERC721.IDMint[] memory mintRequests = new IImmutableERC721.IDMint[](2);
        uint256[] memory tokenIds1 = new uint256[](4);
        tokenIds1[0] = 100;
        tokenIds1[1] = 101;
        tokenIds1[2] = 102;
        tokenIds1[3] = 1000;
        uint256[] memory tokenIds2 = new uint256[](3);
        tokenIds2[0] = 103;
        tokenIds2[1] = 1001;
        tokenIds2[2] = 1002;
        mintRequests[0].to = user1;
        mintRequests[0].tokenIds = tokenIds1;
        mintRequests[1].to = user2;
        mintRequests[1].tokenIds = tokenIds2;
        vm.startBroadcast();
        erc721.mintBatch(mintRequests);
        
        // Set fee for NFTs 1000 to 1002 to 5%
        uint96 feeNumerator = 200; // 2%
        uint96 otherFeeNumerator = 500;
        uint256[] memory nfts = new uint256[](3);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = 1000 + i;
        }
        // Must be called by minter
        erc721.setNFTRoyaltyReceiverBatch(nfts, royaltyReceiver, otherFeeNumerator);
        vm.stopBroadcast();

        // Do some checks
        require(erc721.balanceOf(user1) == 4, "Balance user1 after initial mint");
        require(erc721.balanceOf(user2) == 3, "Balance user2 after initial mint");
        require(erc721.totalSupply() == 7, "Total supply after initial mint");
        require(erc721.ownerOf(100) == user1, "Owner of 100 after initial mint");
        require(erc721.ownerOf(101) == user1, "Owner of 101 after initial mint");
        require(erc721.ownerOf(102) == user1, "Owner of 102 after initial mint");
        require(erc721.ownerOf(1000) == user1, "Owner of 1000 after initial mint");
        require(erc721.ownerOf(103) == user2, "Owner of 103 after initial mint");
        require(erc721.ownerOf(1001) == user2, "Owner of 1001 after initial mint");
        require(erc721.ownerOf(1002) == user2, "Owner of 1002 after initial mint");

        for (uint256 i = 100; i < 104; i++) {
            (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(i, 10000);
            require(receiver == royaltyReceiver, "Wrong receiver1");
            require(royaltyAmount == feeNumerator, "Wrong fee1");
        }
        for (uint256 i = 1000; i < 103; i++) {
            (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(i, 10000);
            require(receiver == royaltyReceiver, "Wrong receiver2");
            require(royaltyAmount == otherFeeNumerator, "Wrong fee2");
        }
    }

}
