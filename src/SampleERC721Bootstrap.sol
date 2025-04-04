// Copyright (c) 2025 Peter Robinson
// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.19 <0.8.29;

import {ImmutableERC721MintByIDBootstrapV3} from "@imtbl/contracts/token/erc721/preset/ImmutableERC721MintByIDBootstrapV3.sol";

contract SampleERC721Bootstrap is ImmutableERC721MintByIDBootstrapV3 {
    bytes32 private constant _MINTER_ROLE = bytes32("MINTER_ROLE");

    /**
     * @notice Initialises the upgradeable contract. Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param owner_ The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param minter_ The address to grant the `MINTER_ROLE` to
     * @param name_ The name of the collection
     * @param symbol_ The symbol of the collection
     * @param baseURI_ The base URI for the collection
     * @param contractURI_ The contract URI for the collection
     * @param operatorAllowlist_ The address of the operator allowlist
     * @param royaltyReceiver_ The address of the royalty receiver
     * @param feeNumerator_ The royalty fee numerator
     * @dev the royalty receiver and amount (this can not be changed once set)
     */
    function initialize(
        address owner_,
        address minter_,
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address operatorAllowlist_,
        address royaltyReceiver_,
        uint96 feeNumerator_
    ) public virtual {
        super.initialize(
            owner_, name_, symbol_, baseURI_, contractURI_, operatorAllowlist_,
            royaltyReceiver_,
             feeNumerator_);
        _grantRole(_MINTER_ROLE, minter_);
    }
}
