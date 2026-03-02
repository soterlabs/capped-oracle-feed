# CappedOracleFeed

A Chainlink-compatible oracle wrapper that enforces a maximum price cap. Reports `min(sourcePrice, maxPrice)` — if the source feed price exceeds the cap, the oracle returns the cap instead.

Both `latestAnswer()` and `latestRoundData()` apply the same capping logic. All other round metadata (roundId, timestamps, answeredInRound) is passed through from the source unchanged.

## Properties

- Immutable: no admin, no upgradability, no state changes after deployment
- Source feed must use 8 decimals (Chainlink standard for USD pairs)
- `maxPrice` must be positive

## Build & Test

```shell
forge build
forge test
```
