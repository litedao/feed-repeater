pragma solidity ^0.4.8;

import "./repeater.sol";
import "ds-feeds/interface.sol";

contract AverageRepeater is Repeater
{
    function read(bytes12 repeaterId) constant returns (bytes32 value) {
        uint min = uint(repeaters[repeaterId].min);

        if (uint(repeaters[repeaterId].next) > 1 && uint(repeaters[repeaterId].next) > min) {
            uint amount = 0;
            uint quantity = 0;

            for (uint i = 1; i < uint(repeaters[repeaterId].next); i++) {
                if (repeaters[repeaterId].feeds[bytes12(i)].addr != 0) {
                    if (DSFeedsInterface(repeaters[repeaterId].feeds[bytes12(i)].addr).peek(repeaters[repeaterId].feeds[bytes12(i)].position)) {
                        value = DSFeedsInterface(repeaters[repeaterId].feeds[bytes12(i)].addr).read(repeaters[repeaterId].feeds[bytes12(i)].position);

                        amount += uint(value);
                        quantity += 1;
                    }
                }
            }

            if (quantity > 0 && quantity >= min ) {
                return bytes32(amount / quantity);
            }
            return 0;
        }
    }
}
