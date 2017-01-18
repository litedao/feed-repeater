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
    uint256 value1 = 15;
    uint256 value2 = 33;
    uint256 value3 = 71;

    bytes12       id;

    function setUp() {
        assistant._target(aggregator);
        Feedbase200 feed1 = new Feedbase200();
        Feedbase200 feed2 = new Feedbase200();
        Feedbase200 feed3 = new Feedbase200();

        bytes12 position1 = feed1.claim();
        bytes12 position2 = feed2.claim();
        bytes12 position3 = feed3.claim();

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
        assertEq(uint(id), 1);
        assertEq(uint(aggregator.claim()), 2);
    }

    function test_owner() {
        assertEq(aggregator.owner(id), this);
    }

    function test_get() {
        var (value, ok) = aggregator.tryGet(id);
        assertEq32(value, bytes32((value1 + value2 + value3) / 3));
        assertTrue(ok);
    }

    // function test_get() {
    //     expectEventsExact(aggregator);

    //     id = feedbase.claim();
    //     LogClaim(id, address(this));

    //     feedbase.set(id, 0x1234, time() + 1);
    //     LogSet(id, 0x1234, time() + 1);

    //     var (value, ok) = assistant.tryGet(id);
    //     assertEq32(value, 0x1234);
    //     assertTrue(ok);
    // }

    // function test_get_expired() {
    //     expectEventsExact(feedbase);

    //     feedbase.set(id, 0x1234, 123);
    //     LogSet(id, 0x1234, 123);

    //     var (value, ok) = feedbase.tryGet(id);
    //     assertEq32(value, 0);
    //     assertFalse(ok);
    // }

    // function test_payment() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_price(id, 50);
    //     LogSetPrice(id, 50);

    //     feedbase.set(id, 0x1234, time() + 1);
    //     LogSet(id, 0x1234, time() + 1);

    //     token.set_balance(assistant, 2000);

    //     var (value, ok) = assistant.tryGet(id);
    //     LogPay(id, assistant);
    //     assertEq32(value, 0x1234);
    //     assertTrue(ok);

    //     assertEq(token.balances(assistant), 1950);
    // }

    // function test_already_paid() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_price(id, 50);
    //     LogSetPrice(id, 50);

    //     feedbase.set(id, 0x1234, time() + 1);
    //     LogSet(id, 0x1234, time() + 1);

    //     token.set_balance(assistant, 2000);

    //     var (value_1, ok_1) = assistant.tryGet(id);
    //     LogPay(id, assistant);
    //     assertEq32(value_1, 0x1234);
    //     assertTrue(ok_1);

    //     var (value_2, ok_2) = assistant.tryGet(id);
    //     assertEq32(value_2, 0x1234);
    //     assertTrue(ok_2);

    //     assertEq(token.balances(assistant), 1950);
    // }

    // function test_failed_payment_throwing_token() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_price(id, 50);
    //     LogSetPrice(id, 50);

    //     feedbase.set(id, 0x1234, time() + 1);
    //     LogSet(id, 0x1234, time() + 1);

    //     token.set_balance(assistant, 49);

    //     var (value, ok) = assistant.tryGet(id);
    //     assertEq32(value, 0);
    //     assertFalse(ok);

    //     assertEq(token.balances(assistant), 49);
    // }

    // function test_failed_payment_nonthrowing_token() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_price(id, 50);
    //     LogSetPrice(id, 50);

    //     feedbase.set(id, 0x1234, time() + 1);
    //     LogSet(id, 0x1234, time() + 1);

    //     token.set_balance(assistant, 49);
    //     token.disable_throwing();

    //     var (value, ok) = assistant.tryGet(id);
    //     assertEq32(value, 0);
    //     assertFalse(ok);

    //     assertEq(token.balances(assistant), 49);
    // }

    // function testFail_set_price_without_token() {
    //     feedbase.set_price(feedbase.claim(), 50);
    // }

    // function testFail_set_price_unauth() {
    //     PaidFeedbase(assistant).set_price(id, 50);
    // }

    // function test_set_owner() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_owner(id, assistant);
    //     LogSetOwner(id, assistant);

    //     PaidFeedbase(assistant).set_price(id, 50);
    //     LogSetPrice(id, 50);

    //     assertEq(feedbase.price(id), 50);
    // }

    // function testFail_set_owner_unauth() {
    //     Feedbase200(assistant).set_owner(id, assistant);
    // }

    // function test_set_label() {
    //     expectEventsExact(feedbase);

    //     feedbase.set_label(id, "foo");
    //     LogSetLabel(id, "foo");

    //     assertEq32(feedbase.label(id), "foo");
    // }

    // function testFail_set_label_unauth() {
    //     Feedbase200(assistant).set_label(id, "foo");
    // }
}

contract FakePerson is Tester {
    function tryGet(bytes12 id) returns (bytes32, bool) {
        return Feedbase200(_t).tryGet(id);
    }
}
