/// aggregator.sol --- simple feed-oriented data access pattern

// Copyright (C) 2015-2016  Nexus Development <https://nexusdev.us>
// Copyright (C) 2015-2016  Nikolai Mushegian <nikolai@nexusdev.us>
// Copyright (C) 2016       Daniel Brockman   <daniel@brockman.se>

// This file is part of Feedbase.

// Feedbase is free software; you can redistribute and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Feedbase is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with Feedbase.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.4.8;

import "feedbase/interface.sol";
import "./interface.sol";

contract FeedAggregator100 is FeedAggregatorInterface100
                      , FeedAggregatorEvents100
{
    mapping (bytes12 => Aggregator) aggregators;
    bytes12 next = 0x1;

    function time() internal returns (uint40) {
        return uint40(now);
    }

    function assert(bool ok) internal {
        if (!ok) throw;
    }

    struct Aggregator {
        address                 owner;
        bytes32                 label;
        FeedbaseInterface200    feed1;
        bytes12                 position1;
        FeedbaseInterface200    feed2;
        bytes12                 position2;
        FeedbaseInterface200    feed3;
        bytes12                 position3;
    }

    function owner(bytes12 id) constant returns (address) {
        return aggregators[id].owner;
    }
    function label(bytes12 id) constant returns (bytes32) {
        return aggregators[id].label;
    }

    //------------------------------------------------------------------
    // Creating aggregators
    //------------------------------------------------------------------

    function claim() returns (bytes12 id) {
        id = next;
        assert(id != 0x0);

        next = bytes12(uint96(next)+1);

        aggregators[id].owner = msg.sender;

        LogClaim(id, msg.sender);
        return id;
    }

    modifier aggregator_auth(bytes12 id) {
        assert(msg.sender == owner(id));
        _;
    }

    //------------------------------------------------------------------
    // Updating aggregators
    //------------------------------------------------------------------

    function set(bytes12 id, address contract1, bytes12 position1, address contract2, bytes12 position2,
    address contract3, bytes12 position3)
        aggregator_auth(id)
    {
        aggregators[id].feed1 = FeedbaseInterface200(contract1);
        aggregators[id].position1 = position1;

        aggregators[id].feed2 = FeedbaseInterface200(contract2);
        aggregators[id].position2 = position2;

        aggregators[id].feed3 = FeedbaseInterface200(contract3);
        aggregators[id].position3 = position3;

        LogSet(id, contract1, position1, contract2, position2, contract3, position3);
    }

    function set_owner(bytes12 id, address owner)
        aggregator_auth(id)
    {
        aggregators[id].owner = owner;
        LogSetOwner(id, owner);
    }

    function set_label(bytes12 id, bytes32 label)
        aggregator_auth(id)
    {
        aggregators[id].label = label;
        LogSetLabel(id, label);
    }

    //------------------------------------------------------------------
    // Reading aggregators
    //------------------------------------------------------------------

    function tryGet(bytes12 id) returns (bytes32 value, bool ok) {
        // get values for 3 feeds
        var (value1, ok1) = aggregators[id].feed1.tryGet(aggregators[id].position1);
        var (value2, ok2) = aggregators[id].feed2.tryGet(aggregators[id].position2);
        var (value3, ok3) = aggregators[id].feed3.tryGet(aggregators[id].position3);
        
        return (bytes32((uint256(value1) + uint256(value2) + uint256(value3)) / 3), ok1 && ok2 && ok3);
    }

    function get(bytes12 id) returns (bytes32 value) {
        var (val, ok) = tryGet(id);
        if(!ok) throw;
        return val;
    }

}