/*
   Copyright 2017 Nexus Development, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/

pragma solidity ^0.4.8;

import "feedbase/interface.sol";

contract FeedAggregatorEvents100 {
    event LogClaim     (bytes12 indexed id, address owner);
    event LogSet       (bytes12 aggregatorId, bytes12 feedId, FeedbaseInterface200 feedbase, bytes12 position);
    event LogSetOwner  (bytes12 indexed id, address owner);
    event LogSetLabel  (bytes12 indexed id, bytes32 label);
}

contract FeedAggregatorInterface100 {
    function claim(bytes12 minimumValid) returns (bytes12 id);
    function add(bytes12 aggregatorId, FeedbaseInterface200 feedbase, bytes12 position);
    function set(bytes12 aggregatorId, bytes12 feedId, FeedbaseInterface200 feedbase, bytes12 position);
    function get(bytes12 id) returns (bytes32 value);
    function tryGet(bytes12 id) returns (bytes32 value, bool ok);
}
