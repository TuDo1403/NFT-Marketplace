// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

import "./interfaces/ICurrencyManager.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract CurrencyManager is ICurrencyManager, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private _whitelistedCurrencies;

    function addCurrency(address currency) external override onlyOwner {
        require(
            !_whitelistedCurrencies.contains(currency),
            "Currency: Already whitelisted"
        );
        _whitelistedCurrencies.add(currency);

    }

    function removeCurrency(address currency) external override onlyOwner {
        require(
            _whitelistedCurrencies.contains(currency),
            "Currency: Not whitelisted"
        );
        _whitelistedCurrencies.remove(currency);
    }

    function isCurrencyWhitelisted(address currency)
        external
        view
        override
        returns (bool)
    {
        return _whitelistedCurrencies.contains(currency);
    }

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size)
        external
        view
        override
        returns (address[] memory, uint256)
    {
        uint256 length = size;

        if (length > _whitelistedCurrencies.length() - cursor) {
            length = _whitelistedCurrencies.length() - cursor;
        }

        address[] memory whitelistedCurrencies = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            whitelistedCurrencies[i] = _whitelistedCurrencies.at(cursor + i);
        }

        return (whitelistedCurrencies, cursor + length);
    }

    function viewCountWhitelistedCurrencies()
        external
        view
        override
        returns (uint256)
    {
        return _whitelistedCurrencies.length();
    }
}
