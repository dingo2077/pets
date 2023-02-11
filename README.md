# TaskBoard

A simple contract that allows interaction between the customer and the contractor. The customer can publish tasks, the worker can take them into work, hand over the work.

Files:
- 00-Proxy.sol: Implementation of ERC1967Proxy by OZ;
- 01-Board.sol: Main contract;
- 02-PriceConsumerV3.sol: SC by ChainLink using for calc minimal price of published task (1% of eth);
- 03-MyERC20.sol: ERC20 using for DAO votes.
- 04-DAO.sol: Simple DAO using for with ERC20Votes module.

IMPORTANT! 
DO NOT USE THIS CODE IN PRODUCTION. 
