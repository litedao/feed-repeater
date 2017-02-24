pragma solidity ^0.4.8;

import "./repeater.sol";
import "ds-feeds/interface.sol";

contract AverageRepeater100 is Repeater100
{
    function tryGet(bytes12 repeaterId) returns (bytes32 value, bool ok) {
        uint minimumValid = uint(repeaters[repeaterId].minimumValid);

        if (uint(repeaters[repeaterId].next) > 1 && uint(repeaters[repeaterId].next) > minimumValid) {
            uint amount = 0;
            uint quantity = 0;

            for (uint i = 1; i < uint(repeaters[repeaterId].next); i++) {
                if (repeaters[repeaterId].feeds[bytes12(i)].addr != 0) {
                    (value, ok) = DSFeedsInterface200(repeaters[repeaterId].feeds[bytes12(i)].addr).tryGet(repeaters[repeaterId].feeds[bytes12(i)].position);

                    if(ok) {
                        amount += uint(value);
                        quantity += 1;
                    }
                }
            }

            if (quantity > 0 && quantity >= minimumValid ) {
                return (bytes32(amount / quantity), true);
            }
            return (0, false);
        }
    }
}
