// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {CappedOracleFeed} from "../src/CappedOracleFeed.sol";
import {AggregatorV3Interface} from "../src/interfaces/AggregatorV3Interface.sol";

/// @dev Fork tests against mainnet USDT/USD Chainlink feed.
///      Run with: forge test --mc CappedOracleFeedForkTest --fork-url <RPC_URL>
contract CappedOracleFeedForkTest is Test {
    address constant USDT_USD_FEED = 0x3E7d1eAB13ad0104d2750B8863b489D65364e32D;
    int256 constant MAX_PRICE = 1e8; // $1.00

    // Block 14_765_000 (May 12 2022, UST collapse) — USDT ≈ $0.9975, below cap
    uint256 constant BLOCK_BELOW_CAP = 14_765_000;

    // Block 16_810_000 (Mar 12 2023, SVB crisis) — USDT ≈ $1.0118, above cap
    uint256 constant BLOCK_ABOVE_CAP = 16_810_000;

    function test_fork_price_below_cap() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), BLOCK_BELOW_CAP);

        CappedOracleFeed oracle = new CappedOracleFeed(USDT_USD_FEED, MAX_PRICE);

        (, int256 sourcePrice,,,) = AggregatorV3Interface(USDT_USD_FEED).latestRoundData();
        (, int256 cappedPrice,,,) = oracle.latestRoundData();

        assertLt(sourcePrice, MAX_PRICE, "source price should be below cap");
        assertEq(cappedPrice, sourcePrice, "price below cap should pass through unchanged");
    }

    function test_fork_price_above_cap() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), BLOCK_ABOVE_CAP);

        CappedOracleFeed oracle = new CappedOracleFeed(USDT_USD_FEED, MAX_PRICE);

        (, int256 sourcePrice,,,) = AggregatorV3Interface(USDT_USD_FEED).latestRoundData();
        (, int256 cappedPrice,,,) = oracle.latestRoundData();

        assertGt(sourcePrice, MAX_PRICE, "source price should be above cap");
        assertEq(cappedPrice, MAX_PRICE, "price above cap should be capped");
    }

    function test_fork_metadata_preserved() public {
        vm.createSelectFork(vm.envString("ETH_RPC_URL"), BLOCK_ABOVE_CAP);

        CappedOracleFeed oracle = new CappedOracleFeed(USDT_USD_FEED, MAX_PRICE);

        (uint80 srcRoundId,, uint256 srcStartedAt, uint256 srcUpdatedAt, uint80 srcAnsweredInRound) =
            AggregatorV3Interface(USDT_USD_FEED).latestRoundData();
        (uint80 roundId, int256 cappedPrice, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, srcRoundId);
        assertEq(cappedPrice, MAX_PRICE);
        assertEq(startedAt, srcStartedAt);
        assertEq(updatedAt, srcUpdatedAt);
        assertEq(answeredInRound, srcAnsweredInRound);
    }
}
