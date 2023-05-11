// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Heavily inspired by Gnosis Safe
////    h/t Richard Meissner - @rmeissner

contract SC {
    address public owner;

    mapping(bytes4 => address) permittedCallbackAddress; // TODO: Do we want / can we use? // Ideally enforced in impl

    mapping(bytes4 => address) getCallbackHandler;

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

    /// @notice Set the an address to delegate call to if called with that sig
    function setFallbackHandler(bytes4 sig, address handler) external {
        require(msg.sender == owner);

        getCallbackHandler[sig] = handler;
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
