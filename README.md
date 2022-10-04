# MuseTime contracts

ERC721 contract of MuseTime

## Hardhat

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```

## Frontend

https://github.com/web3nomad/muse-time-app/

## Issues

We use `hardhat-preprocessor` to transforms code to use remappings of Foundry, but it introduces an issue, a `__CACHE_BREAKER__` library is included in each compiled contract.

```json
{
  "libraries": {
    "": {
      "__CACHE_BREAKER__": "0x000000008f5bf6125b026ab8973805365c790d29"
    }
  }
}
```

Generally it could be ignored, because this is a library of empty `""`. But there will be an tip on etherscan "This contract contains unverified libraries: `__CACHE_BREAKER__`"

https://github.com/wighawag/hardhat-preprocessor/blob/dac6c715ce1fa5af83441302d655d8922cfc4880/src/index.ts#L179

Above is the source code of this logic, seems it use a `cacheBreaker` hash to revalidate after settings are changed.

### Solution

1. remove `preprocess` config from `hardhat.config.ts`
2. change `paths.sources` to `./hardhat/contracts` in `hardhat.config.ts`
3. run `npx hardhat preprocess --dest ./hardhat/contracts --config hardhat-preprocess.config.ts` to generate contracts for hardhat and save them to `contracts` folder.

`npm run remap` should be run before `npx hardhat compile`, so hardhat can read the clean transformd contracts.
