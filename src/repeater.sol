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
import "feedbase/interface.sol";

contract Repeater100 is RepeaterInterface100
                      , RepeaterEvents100
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
        bytes12                     minimumValid;
        bytes12                     next;
        mapping (bytes12 => Feed)   feeds;
    }

    struct Feed {
        address                 feedbase;
        bytes12                 position;
    }

    function owner(bytes12 repeaterId) constant returns (address) {
        return repeaters[repeaterId].owner;
    }
    function label(bytes12 repeaterId) constant returns (bytes32) {
        return repeaters[repeaterId].label;
    }
    function minimumValid(bytes12 repeaterId) constant returns (bytes12) {
        return repeaters[repeaterId].minimumValid;
    }
    function feedsQuantity(bytes12 repeaterId) constant returns (bytes12) {
        return bytes12(uint96(repeaters[repeaterId].next)-1);
    }

    //------------------------------------------------------------------
    // Creating repeaters
    //------------------------------------------------------------------

    function claim() returns (bytes12 repeaterId) {
        return claim(1);
    }

    function claim(bytes12 minimumValid) returns (bytes12 repeaterId) {
        repeaterId = next;
        assert(repeaterId != 0x0);

        next = bytes12(uint96(next)+1);

        repeaters[repeaterId].owner = msg.sender;
        repeaters[repeaterId].next = 0x1;

        LogClaim(repeaterId, msg.sender);

        set_minimumValid(repeaterId, minimumValid);

        return repeaterId;
    }

    modifier repeater_auth(bytes12 id) {
        assert(msg.sender == owner(id));
        _;
    }

    //------------------------------------------------------------------
    // Updating repeaters
    //------------------------------------------------------------------

    function set(bytes12 repeaterId, address feedbase, bytes12 position)
         repeater_auth(repeaterId)
         returns (bytes12 feedId)
    {
        feedId = repeaters[repeaterId].next;
        assert(feedId != 0x0);

        repeaters[repeaterId].next = bytes12(uint96(feedId)+1);

        set(repeaterId, feedId, feedbase, position);
        return feedId;
    }

    function set(bytes12 repeaterId, bytes12 feedId, address feedbase, bytes12 position)
         repeater_auth(repeaterId)
    {
        repeaters[repeaterId].feeds[feedId].feedbase = feedbase;
        repeaters[repeaterId].feeds[feedId].position = position;

        LogSet(repeaterId, feedId, feedbase, position);
    }

    function unset(bytes12 repeaterId, bytes12 feedId)
         repeater_auth(repeaterId)
    {
        repeaters[repeaterId].feeds[feedId].feedbase = address(0);
        repeaters[repeaterId].feeds[feedId].position = 0;

        LogUnset(repeaterId, feedId);
    }

    function set_owner(bytes12 repeaterId, address owner)
        repeater_auth(repeaterId)
    {
        repeaters[repeaterId].owner = owner;
        LogSetOwner(repeaterId, owner);
    }

    function set_label(bytes12 repeaterId, bytes32 label)
        repeater_auth(repeaterId)
    {
        repeaters[repeaterId].label = label;
        LogSetLabel(repeaterId, label);
    }

    function set_minimumValid(bytes12 repeaterId, bytes12 minimumValid) 
        repeater_auth(repeaterId)
    {
        repeaters[repeaterId].minimumValid = minimumValid;
        LogMinimumValid(repeaterId, minimumValid);
    }

    //------------------------------------------------------------------
    // Reading repeaters
    //------------------------------------------------------------------

    function getFeedInfo(bytes12 repeaterId, bytes12 feedId) returns (address, bytes12) {
        return (repeaters[repeaterId].feeds[feedId].feedbase, repeaters[repeaterId].feeds[feedId].position);
    }

    function tryGetFeed(bytes12 repeaterId, bytes12 feedId) returns (bytes32, bool) {
        return FeedbaseInterface200(repeaters[repeaterId].feeds[feedId].feedbase).tryGet(repeaters[repeaterId].feeds[feedId].position);
    }

    function get(bytes12 repeaterId) returns (bytes32 value) {
        var (val, ok) = tryGet(repeaterId);
        if(!ok) throw;
        return val;
    }

    function tryGet(bytes12 repeaterId) returns (bytes32 value, bool ok) {
        return (0, false);
    }
}
