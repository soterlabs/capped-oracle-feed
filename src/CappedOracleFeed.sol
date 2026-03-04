// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.28;

import {MinAggregatorV3Interface} from "./interfaces/MinAggregatorV3Interface.sol";

/**
 * @title  CappedOracleFeed
 * @notice A Chainlink-compatible oracle wrapper that enforces a maximum price cap.
 * @dev    Wraps an existing Chainlink price feed and ensures the reported price
 *         never exceeds `maxPrice`.
 *
 *         Implements MinAggregatorV3Interface (decimals, latestRoundData).
 *         Methods like description(), version(), and getRoundData() are intentionally omitted.
 *
 *         Decimals are validated against the source at deployment and assumed stable
 *         thereafter — restricted to 8 (Chainlink standard for USD pairs).
 *         Both `source` and `maxPrice` are immutable — once deployed, the cap cannot
 *         be changed.
 */
contract CappedOracleFeed is MinAggregatorV3Interface {
    error InvalidSource();
    error InvalidDecimals();
    error InvalidMaxPrice();

    MinAggregatorV3Interface public immutable source;
    int256 public immutable maxPrice;

    constructor(address _source, int256 _maxPrice) {
        if (_source == address(0)) revert InvalidSource();
        if (MinAggregatorV3Interface(_source).decimals() != 8) revert InvalidDecimals();
        if (_maxPrice <= 0) revert InvalidMaxPrice();

        source = MinAggregatorV3Interface(_source);
        maxPrice = _maxPrice;
    }

    /// @notice Returns the full round data from the source feed with a capped price.
    /// @dev    All fields except `answer` are passed through unchanged from the source.
    ///         When the cap applies, `answer` is synthetic while round metadata reflects the source round.
    ///         Staleness and validity checks are intentionally omitted — consumers should apply their own.
    function latestRoundData()
        external
        view
        override
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        (roundId, answer, startedAt, updatedAt, answeredInRound) = source.latestRoundData();
        if (answer > maxPrice) answer = maxPrice;
    }

    /// @notice Returns the number of decimals used by this oracle.
    /// @return 8 (Chainlink standard for USD pairs)
    function decimals() external pure override returns (uint8) {
        return 8;
    }
}
