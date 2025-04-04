// Copyright (c) 2025 Peter Robinson
// SPDX-License-Identifier: MIT License
pragma solidity >=0.8.19 <0.8.29;

import {MintingAccessControl} from "@imtbl/contracts/access/MintingAccessControl.sol";
import {ImmutableERC721V2} from "@imtbl/contracts/token/erc721/preset/ImmutableERC721V2.sol";

contract SampleCollectionERC721 is ImmutableERC721V2 {
    /**
     * @notice Grants `DEFAULT_ADMIN_ROLE` to the supplied `owner` address
     * @param _owner The address to grant the `DEFAULT_ADMIN_ROLE` to
     * @param _minter The address to grant the minting role to
     * @param _name The name of the collection
     * @param _symbol The symbol of the collection
     * @param _baseURI The base URI for the collection
     * @param _contractURI The contract URI for the collection
     * @param _operatorAllowlist The address of the operator allowlist
     * @param _royaltyReceiver The address of the royalty receiver
     * @param _feeNumerator The royalty fee numerator
     * @dev the royalty receiver and amount (this can not be changed once set)
     */
    constructor(
        address _owner,
        address _minter,
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        string memory _contractURI,
        address _operatorAllowlist,
        address _royaltyReceiver,
        uint96 _feeNumerator
    )
        ImmutableERC721V2(
            _owner,
            _name,
            _symbol,
            _baseURI,
            _contractURI,
            _operatorAllowlist,
            _royaltyReceiver,
            _feeNumerator
        )
    {
        _grantRole(MintingAccessControl.MINTER_ROLE, _minter);
    }
}
