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
    FakePerson      assistant    = new FakePerson();
    FeedAggregator100  aggregator   = new FeedAggregator100();

    Feedbase200 feed1 = new Feedbase200();
    Feedbase200 feed2 = new Feedbase200();
    Feedbase200 feed3 = new Feedbase200();

    uint256 value1 = 15;
    uint256 value2 = 33;
    uint256 value3 = 71;

    bytes12       id;
    bytes12 position1;
    bytes12 position2;
    bytes12 position3;

    function setUp() {
        assistant._target(aggregator);
        
        position1 = feed1.claim();
        position2 = feed2.claim();
        position3 = feed3.claim();

        feed1.set(position1, bytes32(value1), time() + 1000000);
        feed2.set(position2, bytes32(value2), time() + 1000000);
        feed3.set(position3, bytes32(value3), time() + 1000000);

        id = aggregator.claim();

        aggregator.set(id, feed1, position1, feed2, position2, feed3, position3);

    }

    function time() returns (uint40) {
        return uint40(now);
    }

    function test_claim() {
        expectEventsExact(aggregator);

        assertEq(uint(id), 1);

        assertEq(uint(aggregator.claim()), 2);
        LogClaim(2, this);
    }

    function test_set() {
        expectEventsExact(aggregator);

        aggregator.set(id, feed1, position1, feed2, position2, feed3, position3);

        LogSet(id, feed1, position1, feed2, position2, feed3, position3);
    }

    function test_owner() {
        assertEq(aggregator.owner(id), this);
    }

    function test_get() {
        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(value2));
        assertTrue(ok);
    }

    function test_get_value1() {
        feed1.set(position1, bytes32(12), time() + 1000000);
        feed2.set(position2, bytes32(1), time() + 1000000);
        feed3.set(position3, bytes32(30), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(12));
        assertTrue(ok);
    }

    function test_get_value2() {
        feed1.set(position1, bytes32(34), time() + 1000000);
        feed2.set(position2, bytes32(120), time() + 1000000);
        feed3.set(position3, bytes32(9999), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(120));
        assertTrue(ok);
    }

    function test_get_value3() {
        feed1.set(position1, bytes32(9), time() + 1000000);
        feed2.set(position2, bytes32(25), time() + 1000000);
        feed3.set(position3, bytes32(10), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(10));
        assertTrue(ok);
    }

    function test_get_same_values1() {
        feed1.set(position1, bytes32(10), time() + 1000000);
        feed2.set(position2, bytes32(10), time() + 1000000);
        feed3.set(position3, bytes32(999), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(10));
        assertTrue(ok);
    }

    function test_get_same_values2() {
        feed1.set(position1, bytes32(999), time() + 1000000);
        feed2.set(position2, bytes32(10), time() + 1000000);
        feed3.set(position3, bytes32(10), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(10));
        assertTrue(ok);
    }

    function test_get_same_values3() {
        feed1.set(position1, bytes32(10), time() + 1000000);
        feed2.set(position2, bytes32(999), time() + 1000000);
        feed3.set(position3, bytes32(10), time() + 1000000);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32(10));
        assertTrue(ok);
    }

    function test_get_expired() {
        feed1.set(1, 0x1234, 123);

        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, 0);
        assertFalse(ok);
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
}

contract FakePerson is Tester {
    function tryGet(bytes12 id) returns (bytes32, bool) {
        return Feedbase200(_t).tryGet(id);
    }
}
