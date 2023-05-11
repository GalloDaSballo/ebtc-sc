// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";

contract SCTest is Test {
    function setUp() public {}

    function test_cannotBrickExecute() public {
        // Ensure that calling `execute` cannot be overwritten
    }

    function test_basicSweep() public {
        // Send a token and sweep it out
    }

    function test_setFlashloan() public {
        // Try the flashloan stuff via the SC contract
    }
}
