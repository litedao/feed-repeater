/// aggregator.sol --- simple feed-oriented data access pattern

// Copyright (C) 2015-2017  Nexus Development       <https://nexusdev.us>
// Copyright (C) 2015-2016  Nikolai Mushegian       <nikolai@nexusdev.us>
// Copyright (C) 2016       Daniel Brockman         <daniel@brockman.se>
// Copyright (C) 2017       Mariano Conti           <nanexcool@gmail.com>
// Copyright (C) 2017       Gonzalo Balabasquer     <gbalabasquer@gmail.com>

// This file is part of FeedAggregator.

// FeedAgreggator is free software; you can redistribute and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// FeedAgreggator is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//
// See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License
// along with FeedAggregator.  If not, see <http://www.gnu.org/licenses/>.

/// Commentary:

// One reason why we use `bytes12' for feed IDs is to help prevent
// accidentally confusing different values of the same integer type:
// because `bytes12' is an unusual type, it becomes a lot less likely
// for someone to confuse a feed ID with some other kind of value.
//
// (For example, this is very error-prone when dealing with functions
// that take long lists of various parameters or return many values.)
//
// Another reason is simply to avoid wasting storage, and a third is
// to make the IDs fit in other contexts (such as JavaScript numbers).
//
// Finally, for programming convenience, feeds start at 1 (not 0).

/// Code:

pragma solidity ^0.4.8;

import "./interface.sol";
import "feedbase/interface.sol";

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
        address                     owner;
        bytes32                     label;
        bytes12                     minimumValid;
        bytes12                     next;
        mapping (bytes12 => Feed)   feeds;
    }

    struct Feed {
        address    feedbase;
        bytes12                 position;
    }

    function owner(bytes12 id) constant returns (address) {
        return aggregators[id].owner;
    }
    function label(bytes12 id) constant returns (bytes32) {
        return aggregators[id].label;
    }
    function minimumValid(bytes12 id) constant returns (bytes12) {
        return aggregators[id].minimumValid;
    }

    //------------------------------------------------------------------
    // Creating aggregators
    //------------------------------------------------------------------

    function claim() returns (bytes12 aggregatorId) {
        return claim(1);
    }

    function claim(bytes12 minimumValid) returns (bytes12 aggregatorId) {
        aggregatorId = next;
        assert(aggregatorId != 0x0);

        next = bytes12(uint96(next)+1);

        aggregators[aggregatorId].owner = msg.sender;
        aggregators[aggregatorId].next = 0x1;

        LogClaim(aggregatorId, msg.sender);

        set_minimumValid(aggregatorId, minimumValid);

        return aggregatorId;
    }

    modifier aggregator_auth(bytes12 id) {
        assert(msg.sender == owner(id));
        _;
    }

    //------------------------------------------------------------------
    // Updating aggregators
    //------------------------------------------------------------------

    function set(bytes12 aggregatorId, address feedbase, bytes12 position)
         aggregator_auth(aggregatorId)
    {
        bytes12 feedId = aggregators[aggregatorId].next;
        assert(feedId != 0x0);

        aggregators[aggregatorId].next = bytes12(uint96(feedId)+1);

        set(aggregatorId, feedId, feedbase, position);
    }

    function set(bytes12 aggregatorId, bytes12 feedId, address feedbase, bytes12 position)
         aggregator_auth(aggregatorId)
    {
        aggregators[aggregatorId].feeds[feedId].feedbase = feedbase;
        aggregators[aggregatorId].feeds[feedId].position = position;

        LogSet(aggregatorId, feedId, feedbase, position);
    }

    function set_owner(bytes12 aggregatorId, address owner)
        aggregator_auth(aggregatorId)
    {
        aggregators[aggregatorId].owner = owner;
        LogSetOwner(aggregatorId, owner);
    }

    function set_label(bytes12 aggregatorId, bytes32 label)
        aggregator_auth(aggregatorId)
    {
        aggregators[aggregatorId].label = label;
        LogSetLabel(aggregatorId, label);
    }

    function set_minimumValid(bytes12 aggregatorId, bytes12 minimumValid) 
        aggregator_auth(aggregatorId)
    {
        aggregators[aggregatorId].minimumValid = minimumValid;
        LogMinimumValid(aggregatorId, minimumValid);
    }

    //------------------------------------------------------------------
    // Reading aggregators
    //------------------------------------------------------------------

    function get(bytes12 aggregatorId) returns (bytes32 value) {
        var (val, ok) = tryGet(aggregatorId);
        if(!ok) throw;
        return val;
    }

    function tryGet(bytes12 aggregatorId) returns (bytes32 value, bool ok) {
        uint minimumValid = uint(aggregators[aggregatorId].minimumValid);
        
        if (uint(aggregators[aggregatorId].next) > 1 && uint(aggregators[aggregatorId].next) > minimumValid) {
            mapping (uint => bytes32) values;
            uint next = 0;
           
            for (uint i = 1; i < uint(aggregators[aggregatorId].next); i++) {
                (value, ok) = FeedbaseInterface200(aggregators[aggregatorId].feeds[bytes12(i)].feedbase).tryGet(aggregators[aggregatorId].feeds[bytes12(i)].position);

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

            if (next > 0 && next >= minimumValid) {
                return (values[next / 2], true);
            }
            return (0, false);
        }
    }
}
