// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {SimplifiedDiamondLike} from "../src/SimplifiedDiamondLike.sol";

contract SCTest is Test {
    SimplifiedDiamondLike c;

    address user_1 = address(1);
    function setUp() public {
        vm.startPrank(user_1);
        c = new SimplifiedDiamondLike(user_1);
        vm.stopPrank();
    }

    function test_onlyOwner() public {
        // Ensure that calling `execute` cannot be overwritten
        SimplifiedDiamondLike.Operation[] memory data = new SimplifiedDiamondLike.Operation[](1);
        data[0] = SimplifiedDiamondLike.Operation({
                to: address(address(0)),
                checkSuccess: false,
                value: 0,
                gas: 9999999,
                capGas: false,
                opType: SimplifiedDiamondLike.OperationType.call,
                data: abi.encode(0x0000000000000000000000000000000000000000000000000000000000000001)
        });

        // == NOT OWNER == //
        vm.startPrank(address(2));

        // Cannot Execute
        vm.expectRevert();
        c.execute(data);

        // Cannot change fallbackhandler
        vm.expectRevert();
        c.setFallbackHandler(bytes4(0x12312312), address(123));

        // Cannot set callback mode
        vm.expectRevert();
        c.setOnlyCallbackMode(true);
        
        vm.stopPrank();

        // Owner can
        vm.startPrank(user_1);
        c.execute(data);
        c.setOnlyCallbackMode(true);
        c.setFallbackHandler(bytes4(0x12312312), address(123));
        vm.stopPrank();
    }

    function test_cannotBrickExecute() public {
        vm.startPrank(user_1);
        vm.expectRevert();
        c.setFallbackHandler(bytes4(0x94b24d09), address(123));


        // vm.expectRevert();
        c.setFallbackHandler(c.execute.selector, address(123));
        vm.stopPrank();

    }

    function test_basicSweep() public {
        // Send a token and sweep it out

        // TODO: Deploy ERC20
        // Send it
        // Sweep it away
    }

    function test_setFlashloan() public {
        // Try the flashloan stuff via the SC contract
    }
}
