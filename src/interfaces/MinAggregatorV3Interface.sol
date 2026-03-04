// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/// @notice Minimal subset of Chainlink's AggregatorV3Interface.
///         See https://github.com/smartcontractkit/chainlink-local/blob/main/src/data-feeds/interfaces/AggregatorV3Interface.sol
interface MinAggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}
