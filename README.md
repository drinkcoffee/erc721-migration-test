# ERC721 migration example

This is an example repo showing how to use the (draft) Immutable ERC721 Bootstrap and ERC721v3 upgradeable contract to do a migration.

## Command Sequence

The following is the list of commands used to create this repo.

- Create repo in github. 
- Clone the repo.
- Init Foundry project: 
  - `forge init --force`
- Install Immtuable's contracts repo on branch **peter-upgradeable-erc721**:
  - `forge install https://github.com/immutable/contracts.git@peter-upgradeable-erc721  --no-commit`
- Install Open Zeppelin's upgradeable contracts repo:
  - `forge install https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable  --no-commit`
- Install Open Zeppelin's upgradeable contracts repo for version 4.9.3:
  - `forge install openzeppelin-contracts-upgradeable-4=https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable@v4.9.3  --no-commit`

- Install Open Zeppelin's contracts for version 4.9.3:
  - `forge install openzeppelin-contracts-4=https://github.com/OpenZeppelin/openzeppelin-contracts@v4.9.3  --no-commit
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
- Add SampleCollectionERC721 contract, tests, and script to the src, test, and script directories.




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

