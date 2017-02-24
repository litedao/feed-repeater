pragma solidity ^0.4.8;

import "dapple/script.sol";
import "./repeater.sol";

contract DeployAverageRepeater is Script {
  function DeployAverageRepeater () {
    exportObject("repeater", new AverageRepeater100());
  }
}

contract DeployMedianRepeater is Script {
  function DeployMedianRepeater () {
    exportObject("repeater", new MedianRepeater100());
  }
}
