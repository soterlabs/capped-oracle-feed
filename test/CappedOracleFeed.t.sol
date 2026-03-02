// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import {MockAggregatorV3} from "./mocks/MockAggregatorV3.sol";
import {CappedOracleFeed} from "../src/CappedOracleFeed.sol";

contract CappedOracleFeedTest is Test {
    MockAggregatorV3 priceSource;
    CappedOracleFeed oracle;

    function setUp() public {
        priceSource = new MockAggregatorV3(0.8e8, 8);
        oracle = new CappedOracleFeed(address(priceSource), 1e8);
    }

    // ============================================================
    //  Constructor
    // ============================================================

    function test_constructor() public view {
        assertEq(oracle.latestAnswer(), 0.8e8);
        assertEq(oracle.decimals(), 8);
        assertEq(oracle.maxPrice(), 1e8);
        assertEq(address(oracle.source()), address(priceSource));
    }

    function test_source_zero_address() public {
        vm.expectRevert(CappedOracleFeed.InvalidSource.selector);
        new CappedOracleFeed(address(0), 1e8);
    }

    function test_invalid_decimals() public {
        priceSource.setLatestAnswer(0.8e18);
        priceSource.setDecimals(18);
        vm.expectRevert(CappedOracleFeed.InvalidDecimals.selector);
        new CappedOracleFeed(address(priceSource), 1e18);
    }

    function test_maxPrice_zero() public {
        vm.expectRevert(CappedOracleFeed.InvalidMaxPrice.selector);
        new CappedOracleFeed(address(priceSource), 0);
    }

    function test_maxPrice_negative() public {
        vm.expectRevert(CappedOracleFeed.InvalidMaxPrice.selector);
        new CappedOracleFeed(address(priceSource), -1);
    }

    // ============================================================
    //  latestAnswer
    // ============================================================

    function test_latestAnswer_price_at_max() public {
        priceSource.setLatestAnswer(1e8);
        assertEq(oracle.latestAnswer(), 1e8);
    }

    function test_latestAnswer_price_above_max() public {
        priceSource.setLatestAnswer(1e8 + 1);
        assertEq(oracle.latestAnswer(), 1e8);
    }

    function test_latestAnswer_price_below_max() public {
        priceSource.setLatestAnswer(1e8 - 1);
        assertEq(oracle.latestAnswer(), 1e8 - 1);
    }

    function test_latestAnswer_price_below_zero() public {
        priceSource.setLatestAnswer(-1e8);
        assertEq(oracle.latestAnswer(), -1e8);
    }

    // ============================================================
    //  latestRoundData — price capping
    // ============================================================

    function test_latestRoundData_price_at_max() public {
        priceSource.setLatestAnswer(1e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 1e8);
    }

    function test_latestRoundData_price_above_max() public {
        priceSource.setLatestAnswer(1e8 + 1);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 1e8);
    }

    function test_latestRoundData_price_below_max() public {
        priceSource.setLatestAnswer(1e8 - 1);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 1e8 - 1);
    }

    function test_latestRoundData_price_below_zero() public {
        priceSource.setLatestAnswer(-1e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, -1e8);
    }

    // ============================================================
    //  latestRoundData — metadata pass-through
    // ============================================================

    function test_latestRoundData_forwards_metadata() public {
        priceSource.setRoundData(42, 1000, 2000, 42);
        priceSource.setLatestAnswer(0.9e8);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 42);
        assertEq(answer, 0.9e8);
        assertEq(startedAt, 1000);
        assertEq(updatedAt, 2000);
        assertEq(answeredInRound, 42);
    }

    function test_latestRoundData_forwards_metadata_with_capped_price() public {
        priceSource.setRoundData(99, 3000, 4000, 99);
        priceSource.setLatestAnswer(2e8);

        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) =
            oracle.latestRoundData();

        assertEq(roundId, 99);
        assertEq(answer, 1e8); // capped
        assertEq(startedAt, 3000);
        assertEq(updatedAt, 4000);
        assertEq(answeredInRound, 99);
    }

    // ============================================================
    //  Consistency: latestAnswer == latestRoundData.answer
    // ============================================================

    function test_consistency_below_cap() public {
        priceSource.setLatestAnswer(0.5e8);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(oracle.latestAnswer(), roundAnswer);
    }

    function test_consistency_at_cap() public {
        priceSource.setLatestAnswer(1e8);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(oracle.latestAnswer(), roundAnswer);
    }

    function test_consistency_above_cap() public {
        priceSource.setLatestAnswer(1.5e8);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(oracle.latestAnswer(), roundAnswer);
    }

    function test_consistency_negative() public {
        priceSource.setLatestAnswer(-0.5e8);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(oracle.latestAnswer(), roundAnswer);
    }

    // ============================================================
    //  Stablecoin use case: cap at $1, report actual price if below
    // ============================================================

    function test_stablecoin_depeg_below_cap() public {
        priceSource.setLatestAnswer(0.98e8);

        assertEq(oracle.latestAnswer(), 0.98e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 0.98e8);
    }

    function test_stablecoin_at_cap() public {
        priceSource.setLatestAnswer(1e8);

        assertEq(oracle.latestAnswer(), 1e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 1e8);
    }

    function test_stablecoin_slightly_above_cap() public {
        priceSource.setLatestAnswer(1.001e8);

        assertEq(oracle.latestAnswer(), 1e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 1e8);
    }

    function test_stablecoin_severe_depeg() public {
        priceSource.setLatestAnswer(0.5e8);

        assertEq(oracle.latestAnswer(), 0.5e8);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertEq(answer, 0.5e8);
    }

    // ============================================================
    //  Fuzz tests
    // ============================================================

    function testFuzz_latestAnswer_never_exceeds_max(int256 price) public {
        priceSource.setLatestAnswer(price);
        int256 answer = oracle.latestAnswer();
        assertLe(answer, oracle.maxPrice());
    }

    function testFuzz_latestRoundData_never_exceeds_max(int256 price) public {
        priceSource.setLatestAnswer(price);
        (, int256 answer,,,) = oracle.latestRoundData();
        assertLe(answer, oracle.maxPrice());
    }

    function testFuzz_preserves_source_price_when_below_max(int256 price) public {
        vm.assume(price <= 1e8);
        priceSource.setLatestAnswer(price);

        assertEq(oracle.latestAnswer(), price);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(roundAnswer, price);
    }

    function testFuzz_caps_at_max_when_above(int256 price) public {
        vm.assume(price > 1e8);
        priceSource.setLatestAnswer(price);

        assertEq(oracle.latestAnswer(), 1e8);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(roundAnswer, 1e8);
    }

    function testFuzz_latestAnswer_equals_latestRoundData_answer(int256 price) public {
        priceSource.setLatestAnswer(price);
        (, int256 roundAnswer,,,) = oracle.latestRoundData();
        assertEq(oracle.latestAnswer(), roundAnswer);
    }
}
