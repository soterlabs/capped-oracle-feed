// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/// @notice Mock Chainlink aggregator for testing CappedOracleFeed.
///         Exposes setters for price, decimals, and round metadata.
contract MockAggregatorV3 {
    int256 private _latestAnswer;
    uint8 private _decimals;
    uint80 private _roundId;
    uint256 private _startedAt;
    uint256 private _updatedAt;
    uint80 private _answeredInRound;

    constructor(int256 initialAnswer, uint8 initialDecimals) {
        _latestAnswer = initialAnswer;
        _decimals = initialDecimals;
        _roundId = 1;
        _startedAt = block.timestamp;
        _updatedAt = block.timestamp;
        _answeredInRound = 1;
    }

    function setLatestAnswer(int256 answer) external {
        _latestAnswer = answer;
    }

    function setDecimals(uint8 dec) external {
        _decimals = dec;
    }

    function setRoundData(uint80 roundId, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound) external {
        _roundId = roundId;
        _startedAt = startedAt;
        _updatedAt = updatedAt;
        _answeredInRound = answeredInRound;
    }

    function decimals() external view returns (uint8) {
        return _decimals;
    }

    function latestAnswer() external view returns (int256) {
        return _latestAnswer;
    }

    function latestRoundData()
        external
        view
        returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
    {
        return (_roundId, _latestAnswer, _startedAt, _updatedAt, _answeredInRound);
    }
}
