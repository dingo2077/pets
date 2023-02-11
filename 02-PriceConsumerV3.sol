// SPDX-License-Identifier: MIT
//This is custom version, was adjusted for upgarable version.

 /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */ 

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    //Disable due to the upgradable version.
    
    // constructor() {
    //     priceFeed = AggregatorV3Interface(
    //         0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
    //     );
    // }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e).latestRoundData();
        return price;
    }


}
