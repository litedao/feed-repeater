/// aggregator_test.sol --- functional tests for `aggregator.sol'

// Copyright (C) 2015-2017  Nexus Development <https://nexusdev.us>
// Copyright (C) 2015-2016  Nikolai Mushegian <nikolai@nexusdev.us>
// Copyright (C) 2016       Daniel Brockman   <daniel@brockman.se>
// Copyright (C) 2017       Mariano Conti           <nanexcool@gmail.com>
// Copyright (C) 2017       Gonzalo Balabasquer     <gbalabasquer@gmail.com>

// This file is part of FeedAggregator.

// FeedAggregator is free software; you can redistribute and/or modify it
// under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// FeedAggregator is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty
// of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
// See the GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with FeedAggregator.  If not, see <http://www.gnu.org/licenses/>.

/// Code:

pragma solidity ^0.4.8;

import "dapple/test.sol";
import "feedbase/feedbase.sol";
import "./aggregator.sol";

contract FeedAggregatorTest is Test,
    FeedAggregatorEvents100
{
    FakePerson          assistant   = new FakePerson();
    FeedAggregator100   aggregator  = new FeedAggregator100();
    Feedbase200         feedbase1   = new Feedbase200(); 
    Feedbase200         feedbase2   = new Feedbase200();
    Feedbase200         feedbase3   = new Feedbase200();
    
    bytes12 id;
    bytes12 constant INITIAL_MINIMUM_VALID = 3;

    function setUp() {
        assistant._target(aggregator);
        id = aggregator.claim(INITIAL_MINIMUM_VALID);
    }

    function time() returns (uint40) {
        return uint40(now);
    }

    function test_claim() {
        expectEventsExact(aggregator);

        assertEq(uint(id), 1);

        assertEq(uint(aggregator.claim(1)), 2);

        LogClaim(2, this);
        LogMinimumValid(2, 1);
    }

    function test_claim_with_no_minimum() {
        expectEventsExact(aggregator);

        assertEq(uint(id), 1);

        assertEq(uint(aggregator.claim()), 2);

        LogClaim(2, this);
        LogMinimumValid(2, 1);
    }

    function test_is_owner() {
        assertEq(aggregator.owner(id), this);
    }

    function test_set_owner() {
        expectEventsExact(aggregator);

        aggregator.set_owner(id, assistant);
        LogSetOwner(id, assistant);

        assertEq(aggregator.owner(id), assistant);
    }

    function testFail_set_owner_unauth() {
        Feedbase200(assistant).set_owner(id, assistant);
    }

    function test_set_label() {
        expectEventsExact(aggregator);

        aggregator.set_label(id, "foo");
        LogSetLabel(id, "foo");

        assertEq32(aggregator.label(id), "foo");
    }

    function testFail_set_label_unauth() {
        Feedbase200(assistant).set_label(id, "foo");
    }

    function test_try_get() {
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

        aggregator.add(id, feedbase1, id1);
        aggregator.add(id, feedbase2, id2);
        aggregator.add(id, feedbase3, id3);
        aggregator.add(id, feedbase1, id4);
        aggregator.add(id, feedbase2, id5);

        var (value, ok) = aggregator.tryGet(id);

        assertEq32(value, 11);
        assertTrue(ok);
    }

    function test_try_get_with_two_expired() {
        bytes12 newId = aggregator.claim(3);

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

        aggregator.add(newId, feedbase1, id1);
        aggregator.add(newId, feedbase2, id2);
        aggregator.add(newId, feedbase3, id3);
        aggregator.add(newId, feedbase1, id4);
        aggregator.add(newId, feedbase2, id5);

        var (value, ok) = aggregator.tryGet(newId);

        assertEq32(value, 10);
        assertTrue(ok);
    }

    function test_try_get_with_three_expired() {
        bytes12 newId = aggregator.claim(3);

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

        aggregator.add(newId, feedbase1, id1);
        aggregator.add(newId, feedbase2, id2);
        aggregator.add(newId, feedbase3, id3);
        aggregator.add(newId, feedbase1, id4);
        aggregator.add(newId, feedbase2, id5);

        var (value, ok) = aggregator.tryGet(newId);

        assertEq32(value, 0);
        assertFalse(ok);
    }
}

contract FakePerson is Tester {
    function tryGet(bytes12 id) returns (bytes32, bool) {
        return Feedbase200(_t).tryGet(id);
    }
}
