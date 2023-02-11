// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyERC20 is ERC20Votes {
    
    uint256 public max_supply = 1000000000; 

    constructor(address mintReceiver) ERC20("MyToken", "MTK") ERC20Permit("MyToken") {
        _mint(mintReceiver, max_supply);
       
        
    }

    
}
    
