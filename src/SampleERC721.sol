// Copyright (c) 2025 Peter Robinson
// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDUpgradeableV3} from "@imtbl/contracts/token/erc721/preset/ImmutableERC721MintByIDUpgradeableV3.sol";

contract SampleERC721 is ImmutableERC721MintByIDUpgradeableV3 {
    error NoUpgradesAllowed();

    function upgradeStorage(bytes memory /* _data */) external override {
        // TODO: I don't think there is anything to do here.
    }


    // Called to authorise an upgrade.
    // solhint-disable-next-line no-empty-blocks
    function _authorizeUpgrade(address /* newImplementation */) internal pure override {
        revert NoUpgradesAllowed();
    }
}
