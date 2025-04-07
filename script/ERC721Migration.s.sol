// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {SampleERC721} from "../src/SampleERC721.sol";
import {SampleERC721Bootstrap} from "../src/SampleERC721Bootstrap.sol";
import {IImmutableERC721, IImmutableERC721Errors} from "@imtbl/contracts/token/erc721/interfaces/IImmutableERC721.sol";
import {IImmutableERC721V3} from "@imtbl/contracts/token/erc721/interfaces/IImmutableERC721V3.sol";
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

        console.log("Deploy bootstrap and proxy complete");
    }


    // NOTE: NFTs must be minted before this call.
    function setRoyalties(address _proxy, uint256 _tokenId) public {
        address owner = OWNER;
        address royaltyReceiver = owner;

        IImmutableERC721 erc721Bootstrap = IImmutableERC721(_proxy);

        uint96 otherFeeNumerator = 500;
        uint256[] memory nfts = new uint256[](1);
        nfts[0] = _tokenId;

        // Must be called by minter
        vm.startBroadcast();
        erc721Bootstrap.setNFTRoyaltyReceiverBatch(nfts, royaltyReceiver, otherFeeNumerator);
        vm.stopBroadcast();

        // Do some checks
        (address receiver, uint256 royaltyAmount) = erc721Bootstrap.royaltyInfo(_tokenId, 10000);
        require(receiver == royaltyReceiver, "Wrong receiver2");
        require(royaltyAmount == otherFeeNumerator, "Wrong fee2");

        console.log("setNFTRoyaltyReceiverBatch complete");
    }

    // NOTE: NFTs must be minted before this call.
    function bootstrapChangeOwnership(address _proxy, uint256 _tokenId, address _newOwner) public {
        SampleERC721Bootstrap erc721Bootstrap = SampleERC721Bootstrap(_proxy);

        address oldTokenOwner = erc721Bootstrap.ownerOf(_tokenId);

        // Change ownership of some NFTs
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[] memory requests =
            new ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[](1);
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest memory request1 =
            ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest({from: oldTokenOwner, to: _newOwner, tokenId: _tokenId});
        requests[0] = request1;

        vm.startBroadcast();
        erc721Bootstrap.bootstrapPhaseChangeOwnership(requests);
        vm.stopBroadcast();

        console.log("bootstrapPhaseChangeOwnership complete");
    }



    function deployERC721() public {
        vm.startBroadcast();
        SampleERC721 erc721 = new SampleERC721();
        vm.stopBroadcast();

        console.log("Deployed erc721 implementation to: %x", address(erc721));
    }
    

    function upgrade(address _proxy, address _erc721Impl) public {
        vm.startBroadcast();
        SampleERC721Bootstrap erc721Bootstrap = SampleERC721Bootstrap(_proxy);

        // Execute upgrade
        // A function must be called, so just call the balanceOf view function.
        bytes memory initData = abi.encodeWithSelector(ERC721Upgradeable.balanceOf.selector, address(1));

        vm.startBroadcast();
        erc721Bootstrap.upgradeToAndCall(address(_erc721Impl), initData);
        vm.stopBroadcast();

        IImmutableERC721V3 erc721 = IImmutableERC721V3(_proxy);
        require(erc721.version() == 1, "version");

        console.log("Upgrade complete");
    }
}
