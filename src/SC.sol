// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Diamond} from "./Diamond.sol";

abstract contract SC is Diamond {
    enum OperationType {
        call,
        delegatecall
    }

    struct Operation {
        address to;
        bool checkSuccess;
        uint128 value;
        uint128 gas; // Prob can be smallers
        bool capGas; //  TODO: add
        OperationType opType;
        bytes data;
    }

    // TODO: Move to diamond storage
    address owner;
    mapping(bytes4 => address) callbackHandler;
    bool onlyCallbacks;

    constructor(address _owner) {
        owner = _owner;
    }

    struct CallbackSettings {
        bool onlyCallbacks; // TODO: Refactor to allow not callbacks
        uint256 callbackToggleCheck;
    }

    // TODO: Any setting must be put into a struct
    // And then pseudo-randomized location to avoid clashes

    /// @notice Set the an address to delegate call to if called with that sig
    function setFallbackHandler(bytes4 sig, address handler) external {
        require(msg.sender == owner);

        // "execute((address,bool,uint128,uint128,bool,uint8,bytes)[])": "94b24d09"
        require(sig != 0x94b24d09);
        callbackHandler[sig] = handler;
    }

    function setOnlyCallbackMode(bool _isCallbackmode) external {
        require(msg.sender == owner);

        onlyCallbacks = _isCallbackmode;
    }

    // NOTE: Fallback
    fallback() external payable override {
        super._fallback();
    }

    /// @notice Execute a list of operations in sequence
    function execute(Operation[] calldata ops) external payable {
        require(msg.sender == owner);

        uint256 length = ops.length;
        for (uint256 i; i < length;) {
            _executeOne(ops[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Execute one tx
    function _executeOne(Operation calldata op) internal {
        bool success;
        bytes memory data = op.data;
        uint256 txGas = op.gas;
        address to = op.to;
        uint256 value = op.value;

        if (op.opType == OperationType.delegatecall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }

        if (op.checkSuccess) {
            require(success);
        }
    }
}
