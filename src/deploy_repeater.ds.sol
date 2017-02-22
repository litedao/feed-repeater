pragma solidity ^0.4.8;

import "dapple/script.sol";
import "./repeater.sol";

contract DeployRepeater is Script {
  function DeployRepeater () {
    exportObject("repeater", new Repeater100());
  }
}
