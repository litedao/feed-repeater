pragma solidity ^0.4.8;

import "./repeater.sol";
import "ds-feeds/interface.sol";

contract MedianRepeater100 is Repeater100
{
    function tryGet(bytes12 repeaterId) returns (bytes32 value, bool ok) {
        uint minimumValid = uint(repeaters[repeaterId].minimumValid);

        if (uint(repeaters[repeaterId].next) > 1 && uint(repeaters[repeaterId].next) > minimumValid) {
            mapping (uint => bytes32) values;
            uint next = 0;

            for (uint i = 1; i < uint(repeaters[repeaterId].next); i++) {
                if (repeaters[repeaterId].feeds[bytes12(i)].addr != 0) {
                    (value, ok) = DSFeedsInterface200(repeaters[repeaterId].feeds[bytes12(i)].addr).tryGet(repeaters[repeaterId].feeds[bytes12(i)].position);

                    if(ok) {
                        if (next == 0 || value > values[next - 1]) {
                            values[next] = value;
                        } else {
                            uint j = 0;
                            while (value >= values[j]) {
                                j++;
                            }
                            for (uint k = uint(next); k > j; k--) {
                                values[k] = values[k - 1];
                            }
                            values[j] = value;
                        }
                        next = next + 1;
                    }
                }
            }

            if (next > 0 && next >= minimumValid) {
                return (values[(next - 1) / 2], true);
            }
            return (0, false);
        }
    }
}