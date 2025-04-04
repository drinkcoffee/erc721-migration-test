// Copyright Immutable Pty Ltd 2018 - 2025
// SPDX-License-Identifier: Apache 2.0
pragma solidity >=0.8.19 <0.8.29;

// solhint-disable-next-line no-global-import
import "forge-std/Test.sol";
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

contract SampleERC721V2 is ImmutableERC721MintByIDUpgradeableV3 {
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address /* newImplementation */ ) internal pure override {}
}

contract ERC721MigrationTest is Test {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    string public constant BASE_URI = "https://drinkcoffee.github.io/projects/nfts/";
    string public constant CONTRACT_URI = "https://drinkcoffee.github.io/projects/nfts/sample-collection.json";
    string public constant NAME = "ERC721 Sample Collection";
    string public constant SYMBOL = "SC7";

    // Contracts at the proxy address.
    SampleERC721Bootstrap public erc721Bootstrap;
    IImmutableERC721 public erc721;
    ERC1967Proxy public proxy;

    // Implementation contract upgraded to.
    SampleERC721 public erc721Impl;

    OperatorAllowlistUpgradeable public allowlist;

    address public owner;
    address public minter;
    address public feeReceiver;
    address public operatorAllowListAdmin;
    address public operatorAllowListUpgrader;
    address public operatorAllowListRegistrar;

    string public name;
    string public symbol;
    string public baseURI;
    string public contractURI;
    uint96 public feeNumerator;
    uint96 public otherFeeNumerator;

    address public user1;
    address public user2;
    address public user3;
    uint256 public user1Pkey;

    function setUp() public virtual {
        owner = makeAddr("hubOwner");
        minter = makeAddr("minter");
        feeReceiver = makeAddr("feeReceiver");
        operatorAllowListAdmin = makeAddr("operatorAllowListAdmin");
        operatorAllowListUpgrader = makeAddr("operatorAllowListUpgrader");
        operatorAllowListRegistrar = makeAddr("operatorAllowListRegistrar");

        name = NAME;
        symbol = SYMBOL;
        baseURI = BASE_URI;
        contractURI = CONTRACT_URI;
        feeNumerator = 200; // 2%
        otherFeeNumerator = 500; // 5%

        DeployOperatorAllowlist deployScript = new DeployOperatorAllowlist();
        address proxyAddr =
            deployScript.run(operatorAllowListAdmin, operatorAllowListUpgrader, operatorAllowListRegistrar);
        allowlist = OperatorAllowlistUpgradeable(proxyAddr);

        (user1, user1Pkey) = makeAddrAndKey("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        SampleERC721Bootstrap bootstrapImpl = new SampleERC721Bootstrap();
        erc721Impl = new SampleERC721();

        bytes memory initData = abi.encodeWithSelector(
            SampleERC721Bootstrap.initialize.selector,
            owner,
            minter,
            name,
            symbol,
            baseURI,
            contractURI,
            address(allowlist),
            feeReceiver,
            feeNumerator
        );
        proxy = new ERC1967Proxy(address(bootstrapImpl), initData);

        erc721 = IImmutableERC721(address(proxy));
        erc721Bootstrap = SampleERC721Bootstrap(address(proxy));
    }

    function testEverything() public {
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
        vm.prank(minter);
        erc721.mintBatch(mintRequests);

        assertEq(erc721.balanceOf(user1), 4, "Balance user1 after initial mint");
        assertEq(erc721.balanceOf(user2), 3, "Balance user2 after initial mint");
        assertEq(erc721.balanceOf(user3), 0, "Balance user3 after initial mint");
        assertEq(erc721.totalSupply(), 7, "Total supply after initial mint");
        assertEq(erc721.ownerOf(100), user1, "Owner of 100 after initial mint");
        assertEq(erc721.ownerOf(101), user1, "Owner of 101 after initial mint");
        assertEq(erc721.ownerOf(102), user1, "Owner of 102 after initial mint");
        assertEq(erc721.ownerOf(1000), user1, "Owner of 1000 after initial mint");
        assertEq(erc721.ownerOf(103), user2, "Owner of 103 after initial mint");
        assertEq(erc721.ownerOf(1001), user2, "Owner of 1001 after initial mint");
        assertEq(erc721.ownerOf(1002), user2, "Owner of 1002 after initial mint");

        // Set fee for NFTs 1000 to 1002 to 5%
        uint256[] memory nfts = new uint256[](3);
        for (uint256 i = 0; i < nfts.length; i++) {
            nfts[i] = 1000 + i;
        }
        vm.prank(minter);
        erc721.setNFTRoyaltyReceiverBatch(nfts, feeReceiver, otherFeeNumerator);

        for (uint256 i = 100; i < 104; i++) {
            (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(i, 10000);
            assertEq(receiver, feeReceiver, "Wrong receiver1");
            assertEq(royaltyAmount, feeNumerator, "Wrong fee1");
        }
        for (uint256 i = 1000; i < 103; i++) {
            (address receiver, uint256 royaltyAmount) = erc721.royaltyInfo(i, 10000);
            assertEq(receiver, feeReceiver, "Wrong receiver2");
            assertEq(royaltyAmount, otherFeeNumerator, "Wrong fee2");
        }

        // Change ownership of some NFTs
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[] memory requests =
            new ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest[](2);
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest memory request1 =
            ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest({from: user1, to: user3, tokenId: 100});
        ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest memory request2 =
            ImmutableERC721MintByIDBootstrapV3.BootstrapTransferRequest({from: user2, to: user3, tokenId: 1002});
        requests[0] = request1;
        requests[1] = request2;

        vm.prank(owner);
        erc721Bootstrap.bootstrapPhaseChangeOwnership(requests);

        assertEq(erc721.balanceOf(user1), 3, "Balance user1 after change ownership");
        assertEq(erc721.balanceOf(user2), 2, "Balance user2 after change ownership");
        assertEq(erc721.balanceOf(user3), 2, "Balance user3 after change ownership");
        assertEq(erc721.totalSupply(), 7, "Total supply after change ownership");
        assertEq(erc721.ownerOf(100), user3, "Owner of 100 after change ownership");
        assertEq(erc721.ownerOf(101), user1, "Owner of 101 after change ownership");
        assertEq(erc721.ownerOf(102), user1, "Owner of 102 after change ownership");
        assertEq(erc721.ownerOf(1000), user1, "Owner of 1000 after change ownership");
        assertEq(erc721.ownerOf(103), user2, "Owner of 103 after change ownership");
        assertEq(erc721.ownerOf(1001), user2, "Owner of 1001 after change ownership");
        assertEq(erc721.ownerOf(1002), user3, "Owner of 1002 after change ownership");

        // Execute upgrade
        // A function must be called, so just call the balanceOf view function.
        bytes memory initData = abi.encodeWithSelector(ERC721Upgradeable.balanceOf.selector, address(1));
        vm.prank(owner);
        erc721Bootstrap.upgradeToAndCall(address(erc721Impl), initData);
        assertEq(erc721Bootstrap.version(), 1, "version");

        assertEq(erc721.balanceOf(user1), 3, "Balance user1 after upgrade");
        assertEq(erc721.balanceOf(user2), 2, "Balance user2 after upgrade");
        assertEq(erc721.balanceOf(user3), 2, "Balance user3 after upgrade");
        assertEq(erc721.totalSupply(), 7, "Total supply after upgrade");
        assertEq(erc721.ownerOf(100), user3, "Owner of 100 after upgrade");
        assertEq(erc721.ownerOf(101), user1, "Owner of 101 after upgrade");
        assertEq(erc721.ownerOf(102), user1, "Owner of 102 after upgrade");
        assertEq(erc721.ownerOf(1000), user1, "Owner of 1000 after upgrade");
        assertEq(erc721.ownerOf(103), user2, "Owner of 103 after upgrade");
        assertEq(erc721.ownerOf(1001), user2, "Owner of 1001 after upgrade");
        assertEq(erc721.ownerOf(1002), user3, "Owner of 1002 after upgrade");
    }

    function testNoFurtherUpgrade() public {
        SampleERC721V2 erc721ImplV2 = new SampleERC721V2();

        // Execute upgrade from bootstrap to SampleERC721
        // A function must be called, so just call the balanceOf view function.
        bytes memory initData = abi.encodeWithSelector(ERC721Upgradeable.balanceOf.selector, address(1));
        vm.prank(owner);
        erc721Bootstrap.upgradeToAndCall(address(erc721Impl), initData);
        assertEq(erc721Bootstrap.version(), 1, "version");

        // Attempt to upgrade from SampleERC721 to SampleERC721V2
        vm.prank(owner);
        vm.expectRevert(SampleERC721.NoUpgradesAllowed.selector);
        erc721Bootstrap.upgradeToAndCall(address(erc721ImplV2), initData);
    }
}
