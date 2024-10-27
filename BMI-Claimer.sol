/**
 *Submitted for verification at basescan.org on 2024-10-27
*/

// SPDX-License-Identifier: MIT
// Author: 0xNaixi
// 验证码平台 https://www.nocaptcha.io/register?c=hLf08E
pragma solidity ^0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
    // Bmi
    function mint() external ;
}

contract BmiClaimer {
    //====== mini代理合约配置 ======//
    address private immutable owner = msg.sender;
    address private immutable original = address(this);
    IERC20 constant BmiToken = IERC20(0x2F16386bB37709016023232523FF6d9DAF444BE3);
    // toAddress 对应的 已经使用过的 index
    mapping(address => uint256) public miniAddressIndex;

    constructor() {}

    modifier onlyOwner() {
        require(
            owner == msg.sender || msg.sender == original,
            "Ownable: caller is not the owner"
        );
        _;
    }

    receive() external payable {}

    //查询合约内代币余额
    function getBalanceToken(
        address token
    ) public view virtual returns (uint256 balance) {
        balance = IERC20(token).balanceOf(address(this));
    }

    //提取合约内代币
    function withdrawToken(address token, address to) public onlyOwner {
        uint256 balance = getBalanceToken(token);
        IERC20(token).transfer(to, balance);
    }

    //提取合约内eth
    function withdrawETH(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
    }

    //====== clone factory function ======//
    event NewClone(address clone, address owner);

    // 此函数用于 claim BmiToken 不懂的话 就调用这个
    function arb_ybtltp(uint256 _num) public {
        uint256 index = miniAddressIndex[msg.sender];
        for (uint256 i = index; i < index + _num; ++i) {
            address instance = cloneDeterministic(
                original,
                keccak256(abi.encodePacked(msg.sender, i))
            );
            emit NewClone(instance, address(this));
            BmiClaimer(payable(instance)).mintToken();
            BmiClaimer(payable(instance)).withdrawToken(address(BmiToken), msg.sender);
        }
        miniAddressIndex[msg.sender] = index + _num;
    }


    //不懂不要调用 这是已经创建好的mini 合约 可以冷却期过了之后再次调用
    function mint_custom(uint256 firstIndex,uint256 endIndex) public {
        if(endIndex > miniAddressIndex[msg.sender]){
            endIndex = miniAddressIndex[msg.sender];
        }
        require(firstIndex > endIndex, "Are you sure?");

        for (uint256 i = firstIndex; i < endIndex; ++i) {
            BmiClaimer miniProxy = BmiClaimer(
                payable(proxyFor(msg.sender, i))
            );
            miniProxy.mintToken();
            miniProxy.withdrawToken(address(BmiToken), msg.sender);
        }
    }


    function mintToken() public {
        BmiToken.mint();
    }

    //====== clone factory function ======//
    function cloneDeterministic(
        address implementation,
        bytes32 salt
    ) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
        // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
        // of the `implementation` address with the bytecode before the address.
            mstore(
                0x00,
                or(
                    shr(0xe8, shl(0x60, implementation)),
                    0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000
                )
            )
        // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(
                0x20,
                or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3)
            )
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    function proxyFor(
        address toAddress,
        uint256 index
    ) public view returns (address predicted) {
        /// @solidity memory-safe-assembly
        predicted = predictDeterministicAddress(
            original,
            keccak256(abi.encodePacked(toAddress, index)),
            address(this)
        );
    }
}