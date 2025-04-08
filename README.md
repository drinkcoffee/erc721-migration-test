# ERC721 migration example

This is an example repo showing how to use the (draft) Immutable ERC721 Bootstrap and ERC721v3 upgradeable contract to do a migration.

# Process for migration
The following steps should be followed to demonstrate a migration.

* Deploy the ERC721 proxy and bootstrap. Set-up required environment variables and then:
```
sh script/deployBootstrap.sh
```
* Set the contracts up in hub. Both the proxy and bootstrap contract must be added to a project using the Link Contract feature.
* Grant minter role on the contract. Note the call is to the proxy contract. Set-up required environment variables and then:
```
sh script/grantMinterRole.sh
```
* Mint a single NFT using the Minting API.
```
sh script/mintNFTs.sh
```
* Go to Blockscout and confirm that you can see the NFT graphics when using the token view for the proxy contract. For instance: https://explorer.testnet.immutable.com/token/0xE040E3810db20d791D4823afD1327438a7B48cD4 Doing this ensures the linkage has been correctly set-up between the proxy and the bootstrap contract.
* Go to Blockscout to confirm that a call to transferFrom fails on the proxy contract fails. Doing this ensures that the bootstrap contract has been deployed, and not mistakenly an operational ERC721 contract.
* Mint NFTs using the Minting API. The script needs to be editted for each NFT. Ensure token ids and reference ids are unique. Call:
```
sh script/mintNFTs.sh
```
* Set royalties that will be non-standard. This script only sets one NFT at a time. 
```
sh script/setRoyalties.sh
```
* Force change ownership of NFTs. This script only changes one NFT at a time.
```
sh script/forceChangeOwnership.sh
```
* Deploy the upgradeable ERC721 contract.
```
sh script/deployERC721.sh
```
* Add the newly deployed ERC721 implementation to Hub using the Link Contract feature.
* Upgrade the proxy contract.
```
sh script/upgrade.sh
```
* Go to Blockscout and confirm that the implementation contract for the proxy is now the newly deployed ERC721.
* Go to blockscout and confirm that a call to transferFrom works.
* Go to hub and unlink the bootstrap contract.



## Command Sequence

The following is the list of commands used to create this repo.

- Create repo in github. 
- Clone the repo.
- Init Foundry project: 
  - `forge init --force`
- Install Immtuable's contracts repo on branch **peter-upgradeable-erc721**:
  
```
forge install https://github.com/immutable/contracts.git@peter-upgradeable-erc721  --no-commit
```
- Install Open Zeppelin's upgradeable contracts repo:

```
forge install https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable  --no-commit
```

- Install Open Zeppelin's upgradeable contracts repo for version 4.9.3:

```
forge install openzeppelin-contracts-upgradeable-4=https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.9.3  --no-commit
```

- Install Open Zeppelin's contracts for version 4.9.3:

```
forge install openzeppelin-contracts-4=https://github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3  --no-commit
```

- Add `./remappings.txt` with contents:

```
@openzeppelin-contracts-upgradeable-4/=lib/openzeppelin-contracts-upgradeable-4/contracts/
@openzeppelin-contracts-4/=lib/openzeppelin-contracts-4/contracts/
openzeppelin-contracts-upgradeable-4.9.3/=lib/openzeppelin-contracts-upgradeable-4/contracts/
@imtbl/=lib/contracts.git/
```

- Update `./.gitignore` to ignore Apple file and to igore the `broadcast` directory. Go from:
```
# Compiler files
cache/
out/

# Ignores development broadcast logs
!/broadcast
/broadcast/*/31337/
/broadcast/**/dry-run/

# Docs
docs/

# Dotenv file
.env
```
to:
```
# Compiler files
cache/
out/

# Ignores development broadcast logs
/broadcast
/broadcast/*/31337/
/broadcast/**/dry-run/

# Docs
docs/

# Dotenv file
.env

.DS_Store
```
- Remove `Counter` example contract, tests, and script from the src, test, and script directories.
- Add sample migration contract, tests, and script to the src, test, and script directories.



### Build

```shell
$ forge build
```

### Deploy

Not that `script/deploy.sh` needs small modifications to switch between mainnet and testnet. It also has instructions if deploying using a Ledger hardware wallet.

```shell
$ export PKEY=<your key>
$ export APIKEY=<your blockscout test net or mainnet API key>
$ sh script/deploy.sh
```



### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```

