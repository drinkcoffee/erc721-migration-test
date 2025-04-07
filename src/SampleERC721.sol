// Copyright (c) 2025 Peter Robinson
// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDUpgradeableV3} from
    "@imtbl/contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721Upgradeable} from "openzeppelin-contracts-upgradeable-4.9.3/token/ERC721/ERC721Upgradeable.sol";

contract SampleERC721 is ImmutableERC721MintByIDUpgradeableV3 {
    using Strings for uint256;

    error NoUpgradesAllowed();

    /**
     * Have tokenURI return:
     *  baseURI <token id> .json
     */
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }

    function upgradeStorage(bytes memory /* _data */ ) external override {
        // TODO: I don't think there is anything to do here.
    }

    // Called to authorise an upgrade.
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address /* newImplementation */ ) internal pure override {
        revert NoUpgradesAllowed();
    }
}
