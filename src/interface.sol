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

contract RepeaterEvents {
    event LogClaim     (bytes12 indexed id, address owner);
    event LogSet       (bytes12 indexed id, bytes12 feedId, address addr, bytes12 position);
    event LogUnset     (bytes12 indexed id, bytes12 feedId);
    event LogSetOwner  (bytes12 indexed id, address owner);
    event LogSetLabel  (bytes12 indexed id, bytes32 label);
    event LogSetMin    (bytes12 indexed id, bytes12 min);
}

contract RepeaterInterface {
    function claim() returns (bytes12 id);
    function claim(bytes12 min) returns (bytes12 id);
    function set_min(bytes12 id, bytes12 min);
    function set(bytes12 id, address addr, bytes12 position) returns (bytes12 feedId);
    function set(bytes12 id, bytes12 feedId, address addr, bytes12 position);
    function unset(bytes12 id, bytes12 feedId);
    function peek(bytes12 id) constant returns (bool ok);
    function read(bytes12 id) constant returns (bytes32 value);
}
