/// average_repeater_test.sol --- functional tests for `repeater.sol'

// Copyright (C) 2015-2017  Nexus Development <https://nexusdev.us>
// Copyright (C) 2015-2016  Nikolai Mushegian <nikolai@nexusdev.us>
// Copyright (C) 2016       Daniel Brockman   <daniel@brockman.se>
// Copyright (C) 2017       Mariano Conti           <nanexcool@gmail.com>
// Copyright (C) 2017       Gonzalo Balabasquer     <gbalabasquer@gmail.com>

// This file is part of Repeater.

// Repeater is free software; you can redistribute and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// Repeater is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Repeater.  If not, see <http://www.gnu.org/licenses/>.

/// Code:

pragma solidity ^0.4.8;

import "ds-test/test.sol";
import "ds-feeds/feeds.sol";
import "./average_repeater.sol";

contract AverageRepeaterTest is DSTest,
    RepeaterEvents
{
    Repeater        repeater    = new AverageRepeater();
    DSFeeds         feedbase1   = new DSFeeds(); 
    DSFeeds         feedbase2   = new DSFeeds();
    DSFeeds         feedbase3   = new DSFeeds();
    FakePerson      assistant;
    
    bytes12 id;
    bytes12 constant INITIAL_MINIMUM_VALID = 3;

    function setUp() {
        assistant = new FakePerson(repeater);
        id = repeater.claim(INITIAL_MINIMUM_VALID);
    }

    function time() returns (uint40) {
        return uint40(now);
    }

    function test_claim() {
        expectEventsExact(repeater);

        assertEq(uint(id), 1);

        assertEq(uint(repeater.claim(1)), 2);

        LogClaim(2, this);
        LogSetMin(2, 1);
    }

    function test_claim_with_no_minimum() {
        expectEventsExact(repeater);

        assertEq(uint(id), 1);

        assertEq(uint(repeater.claim()), 2);

        LogClaim(2, this);
        LogSetMin(2, 1);
    }

    function test_is_owner() {
        assertEq(repeater.owner(id), this);
    }

    function test_set_owner() {
        expectEventsExact(repeater);

        repeater.set_owner(id, assistant);
        LogSetOwner(id, assistant);

        assertEq(repeater.owner(id), assistant);
    }

    function testFail_set_owner_unauth() {
        DSFeeds(assistant).set_owner(id, assistant);
    }

    function test_set_label() {
        expectEventsExact(repeater);

        repeater.set_label(id, "foo");
        LogSetLabel(id, "foo");

        assertEq32(repeater.label(id), "foo");
    }

    function testFail_set_label_unauth() {
        DSFeeds(assistant).set_label(id, "foo");
    }

    function test_read() {
        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11);
        
        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5);
        
        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        bytes12 id4 = feedbase1.claim();
        feedbase1.set(id4, 16);

        bytes12 id5 = feedbase2.claim();
        feedbase2.set(id5, 18);

        repeater.set(id, feedbase1, id1);
        repeater.set(id, feedbase2, id2);
        repeater.set(id, feedbase3, id3);
        repeater.set(id, feedbase1, id4);
        repeater.set(id, feedbase2, id5);

        var ok = repeater.peek(id);
        var value = repeater.read(id);

        assert(ok);
        assertEq32(value, 12);
    }

    function test_try_get_feed() {
        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 50);

        repeater.set(id, feedbase1, id1);

        var value = repeater.readFeed(id, id1);

        assertEq32(value, 50);
    }

    function test_get_feedInfo() {
        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 50);

        repeater.set(id, feedbase1, id1);

        var (f, p) = repeater.getFeedInfo(id, id1);

        assertEq(f, feedbase1);
        assertEq(p, id1);
    }

    function test_feeds_quantity() {
        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11);

        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5);

        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        repeater.set(id, feedbase1, id1);
        repeater.set(id, feedbase2, id2);
        repeater.set(id, feedbase3, id3);

        var feedsQuantity = uint(repeater.feedsQuantity(id));

        assertEq(feedsQuantity, 3);
    }

    function test_read_with_two_expired() {
        bytes12 newId = repeater.claim(3);

        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11, 0); // expired
        
        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5);
        
        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        bytes12 id4 = feedbase1.claim();
        feedbase1.set(id4, 16, 0); // expired

        bytes12 id5 = feedbase2.claim();
        feedbase2.set(id5, 18);

        repeater.set(newId, feedbase1, id1);
        repeater.set(newId, feedbase2, id2);
        repeater.set(newId, feedbase3, id3);
        repeater.set(newId, feedbase1, id4);
        repeater.set(newId, feedbase2, id5);

        var ok = repeater.peek(newId);
        var value = repeater.read(newId);

        assert(ok);
        assertEq32(value, 11);
    }

    function testFail_read_with_three_expired() {
        bytes12 newId = repeater.claim(3);

        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11, 0);  // expired
        
        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5, 0);  // expired
        
        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        bytes12 id4 = feedbase1.claim();
        feedbase1.set(id4, 16, 0);  // expired

        bytes12 id5 = feedbase2.claim();
        feedbase2.set(id5, 18);

        repeater.set(newId, feedbase1, id1);
        repeater.set(newId, feedbase2, id2);
        repeater.set(newId, feedbase3, id3);
        repeater.set(newId, feedbase1, id4);
        repeater.set(newId, feedbase2, id5);

        var value = repeater.read(newId);
    }

    function test_read_with_three_expired() {
        bytes12 newId = repeater.claim(3);

        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11, 0);  // expired
        
        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5, 0);  // expired
        
        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        bytes12 id4 = feedbase1.claim();
        feedbase1.set(id4, 16, 0);  // expired

        bytes12 id5 = feedbase2.claim();
        feedbase2.set(id5, 18);

        repeater.set(newId, feedbase1, id1);
        repeater.set(newId, feedbase2, id2);
        repeater.set(newId, feedbase3, id3);
        repeater.set(newId, feedbase1, id4);
        repeater.set(newId, feedbase2, id5);

        var ok = repeater.peek(newId);
        
        assert(!ok);
    }

    function test_unset() {
        bytes12 newId = repeater.claim(3);

        bytes12 id1 = feedbase1.claim();
        feedbase1.set(id1, 11);

        bytes12 id2 = feedbase2.claim();
        feedbase2.set(id2, 5);

        bytes12 id3 = feedbase3.claim();
        feedbase3.set(id3, 10);

        bytes12 id4 = feedbase1.claim();
        feedbase1.set(id4, 16);

        bytes12 id5 = feedbase2.claim();
        feedbase2.set(id5, 18);

        bytes12 feedId1 = repeater.set(newId, feedbase1, id1);
        bytes12 feedId2 = repeater.set(newId, feedbase2, id2);
        bytes12 feedId3 = repeater.set(newId, feedbase3, id3);
        bytes12 feedId4 = repeater.set(newId, feedbase1, id4);
        bytes12 feedId5 = repeater.set(newId, feedbase2, id5);

        var ok = repeater.peek(newId);
        var value = repeater.read(newId);

        assert(ok);
        assertEq32(value, 12);

        repeater.unset(newId, feedId1);
        repeater.unset(newId, feedId2);

        ok = repeater.peek(newId);
        value = repeater.read(newId);

        assert(ok);
        assertEq32(value, 14);

        repeater.set(newId, feedbase2, id2);

        ok = repeater.peek(newId);
        value = repeater.read(newId);

        assert(ok);
        assertEq32(value, 12);
    }
}

contract FakePerson {
    Repeater repeater;

    function FakePerson(Repeater repeater_) {
        repeater  = repeater_;
    }

    function read(bytes12 id) returns (bytes32) {
        return repeater.read(id);
    }
}
