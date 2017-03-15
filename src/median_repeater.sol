pragma solidity ^0.4.8;

import "./repeater.sol";
import "ds-feeds/interface.sol";

contract MedianRepeater is Repeater
{
    function tryGet(bytes12 repeaterId) constant returns (bytes32 value, bool ok) {
        uint minimumValid = uint(repeaters[repeaterId].minimumValid);

        if (uint(repeaters[repeaterId].next) > 1 && uint(repeaters[repeaterId].next) > minimumValid) {
            bytes32[] memory values = new bytes32[](uint(repeaters[repeaterId].next));
            uint next = 0;
            for (uint i = 1; i < uint(repeaters[repeaterId].next); i++) {
                if (repeaters[repeaterId].feeds[bytes12(i)].addr != 0) {
                    (value, ok) = DSFeedsInterface(repeaters[repeaterId].feeds[bytes12(i)].addr).tryGet(repeaters[repeaterId].feeds[bytes12(i)].position);

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