/// repeater.sol --- simple feed-oriented data access pattern

// Copyright (C) 2015-2017  Nexus Development       <https://nexusdev.us>
// Copyright (C) 2015-2016  Nikolai Mushegian       <nikolai@nexusdev.us>
// Copyright (C) 2016       Daniel Brockman         <daniel@brockman.se>
// Copyright (C) 2017       Mariano Conti           <nanexcool@gmail.com>
// Copyright (C) 2017       Gonzalo Balabasquer     <gbalabasquer@gmail.com>

// This file is part of Repeater.

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
// along with Repeater.  If not, see <http://www.gnu.org/licenses/>.

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
import "ds-feeds/interface.sol";

contract Repeater is RepeaterInterface
                      , RepeaterEvents
{
    mapping (bytes12 => Repeater) repeaters;
    bytes12 next = 0x1;

    function time() internal returns (uint40) {
        return uint40(now);
    }

    function assert(bool ok) internal {
        if (!ok) throw;
    }

    struct Repeater {
        address                     owner;
        bytes32                     label;
        bytes12                     min;
        bytes12                     next;
        mapping (bytes12 => Feed)   feeds;
    }

    struct Feed {
        address                 addr;
        bytes12                 position;
    }

    function owner(bytes12 id) constant returns (address) {
        return repeaters[id].owner;
    }
    function label(bytes12 id) constant returns (bytes32) {
        return repeaters[id].label;
    }
    function min(bytes12 id) constant returns (bytes12) {
        return repeaters[id].min;
    }
    function feedsQuantity(bytes12 id) constant returns (bytes12) {
        return bytes12(uint96(repeaters[id].next)-1);
    }

    //------------------------------------------------------------------
    // Creating repeaters
    //------------------------------------------------------------------

    function claim() returns (bytes12 id) {
        return claim(1);
    }

    function claim(bytes12 min) returns (bytes12 id) {
        id = next;
        assert(id != 0x0);

        next = bytes12(uint96(next)+1);

        repeaters[id].owner = msg.sender;
        repeaters[id].next = 0x1;

        LogClaim(id, msg.sender);

        set_min(id, min);

        return id;
    }

    modifier repeater_auth(bytes12 id) {
        assert(msg.sender == owner(id));
        _;
    }

    //------------------------------------------------------------------
    // Updating repeaters
    //------------------------------------------------------------------

    function set(bytes12 id, address addr, bytes12 position)
         repeater_auth(id)
         returns (bytes12 feedId)
    {
        feedId = repeaters[id].next;
        assert(feedId != 0x0);

        repeaters[id].next = bytes12(uint96(feedId)+1);

        set(id, feedId, addr, position);
        return feedId;
    }

    function set(bytes12 id, bytes12 feedId, address addr, bytes12 position)
         repeater_auth(id)
    {
        repeaters[id].feeds[feedId].addr = addr;
        repeaters[id].feeds[feedId].position = position;

        LogSet(id, feedId, addr, position);
    }

    function unset(bytes12 id, bytes12 feedId)
         repeater_auth(id)
    {
        repeaters[id].feeds[feedId].addr = address(0);
        repeaters[id].feeds[feedId].position = 0;

        LogUnset(id, feedId);
    }

    function set_owner(bytes12 id, address owner)
        repeater_auth(id)
    {
        repeaters[id].owner = owner;
        LogSetOwner(id, owner);
    }

    function set_label(bytes12 id, bytes32 label)
        repeater_auth(id)
    {
        repeaters[id].label = label;
        LogSetLabel(id, label);
    }

    function set_min(bytes12 id, bytes12 min) 
        repeater_auth(id)
    {
        repeaters[id].min = min;
        LogSetMin(id, min);
    }

    //------------------------------------------------------------------
    // Reading repeaters
    //------------------------------------------------------------------

    function getFeedInfo(bytes12 id, bytes12 feedId) constant returns (address, bytes12) {
        return (repeaters[id].feeds[feedId].addr, repeaters[id].feeds[feedId].position);
    }

    function peekFeed(bytes12 id, bytes12 feedId) constant returns (bool) {
        return DSFeedsInterface(repeaters[id].feeds[feedId].addr).peek(repeaters[id].feeds[feedId].position);
    }

    function readFeed(bytes12 id, bytes12 feedId) constant returns (bytes32) {
        return DSFeedsInterface(repeaters[id].feeds[feedId].addr).read(repeaters[id].feeds[feedId].position);
    }

    function peek(bytes12 id) constant returns (bool ok) {
        ok = false;
        uint min = uint(repeaters[id].min);

        if (uint(repeaters[id].next) > 1 && uint(repeaters[id].next) > min) {
            uint next = 0;
            uint valid = 0;
            for (uint i = 1; i < uint(repeaters[id].next); i++) {
                if (repeaters[id].feeds[bytes12(i)].addr != 0) {
                    ok = peekFeed(id, bytes12(i));
                    if (ok) valid++;
                }
            }
            ok = valid >= min;
        }
    }

    function read(bytes12 id) constant returns (bytes32 value);
}
