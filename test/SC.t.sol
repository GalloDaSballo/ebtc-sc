// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {SimplifiedDiamondLike} from "../src/SimplifiedDiamondLike.sol";
import {ERC20PresetFixedSupply, ERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";

contract SCTest is Test {
    SimplifiedDiamondLike contractWallet;
    ERC20PresetFixedSupply token;

    address user_1 = address(1);
    address extra_user = address(60);
    address attacker = address(2);
    function setUp() public {
        vm.startPrank(user_1);
        contractWallet = new SimplifiedDiamondLike(user_1);
        vm.stopPrank();

        vm.startPrank(extra_user);
        token = new ERC20PresetFixedSupply("Test", "TEST", 12000, extra_user);
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
        contractWallet.execute(data);

        // Cannot change fallbackhandler
        vm.expectRevert();
        contractWallet.setFallbackHandler(bytes4(0x12312312), address(123));

        // Cannot set callback mode
        vm.expectRevert();
        contractWallet.setOnlyCallbackMode(true);
        
        vm.stopPrank();

        // Owner can
        vm.startPrank(user_1);
        contractWallet.execute(data);
        contractWallet.setOnlyCallbackMode(true);
        contractWallet.setFallbackHandler(bytes4(0x12312312), address(123));
        vm.stopPrank();
    }

    function test_cannotBrickExecute() public {
        vm.startPrank(user_1);
        vm.expectRevert();
        contractWallet.setFallbackHandler(bytes4(0x94b24d09), address(123));


        // vm.expectRevert();
        contractWallet.setFallbackHandler(contractWallet.execute.selector, address(123));
        vm.stopPrank();

    }

    function test_basicSweep() public {
        // Send a token and sweep it out
        vm.startPrank(extra_user);
        token.transfer(address(contractWallet), 123);
        vm.stopPrank();


        // Sweep it away

        address recipient = address(99);

        SimplifiedDiamondLike.Operation[] memory data = new SimplifiedDiamondLike.Operation[](1);
        data[0] = SimplifiedDiamondLike.Operation({
                to: address(address(token)),
                checkSuccess: true,
                value: 0,
                gas: 9999999,
                capGas: false,
                opType: SimplifiedDiamondLike.OperationType.call,
                data: abi.encodeCall(ERC20.transfer, (recipient, 123))
        });

        vm.startPrank(user_1);
        contractWallet.execute(data);
        vm.stopPrank();

        assertEq(token.balanceOf(recipient), 123, "Recipient got the tokens");



    }

    function test_setFlashloan() public {
        // Try the flashloan stuff via the SC contract
    }
}
