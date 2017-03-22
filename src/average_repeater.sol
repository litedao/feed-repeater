pragma solidity ^0.4.8;

import "./repeater.sol";

contract AverageRepeater is Repeater
{
    function read(bytes12 id) constant returns (bytes32) {
        uint min = uint(repeaters[id].min);

        if (uint(repeaters[id].next) > 1 && uint(repeaters[id].next) > min) {
            uint amount = 0;
            uint quantity = 0;
            bytes32 value;
            for (uint i = 1; i < uint(repeaters[id].next); i++) {
                if (repeaters[id].feeds[bytes12(i)].addr != 0) {
                    if (peekFeed(id, bytes12(i))) {
                        value = readFeed(id, bytes12(i));
                        amount += uint(value);
                        quantity += 1;
                    }
                }
            }

            if (quantity > 0 && quantity >= min ) {
                return bytes32(amount / quantity);
            }
        }
        throw;
    }
}
