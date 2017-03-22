pragma solidity ^0.4.8;

import "./repeater.sol";
import "ds-feeds/interface.sol";

contract MedianRepeater is Repeater
{
    function read(bytes12 id) constant returns (bytes32) {
        uint min = uint(repeaters[id].min);

        if (uint(repeaters[id].next) > 1 && uint(repeaters[id].next) > min) {
            bytes32[] memory values = new bytes32[](uint(repeaters[id].next));
            uint next = 0;
            bytes32 value;
            for (uint i = 1; i < uint(repeaters[id].next); i++) {
                if (repeaters[id].feeds[bytes12(i)].addr != 0) {
                    if (peekFeed(id, bytes12(i))) {
                        value = readFeed(id, bytes12(i));
                        if (next == 0 || value >= values[next - 1]) {
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
                        next++;
                    }
                }
            }
            
            if (next > 0 && next >= min) {
                return values[(next - 1) / 2];
            }
        }
        throw;
    }
}