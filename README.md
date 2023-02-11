# TaskBoard

A simple contract that allows interaction between the task publisher and the worker. The task publisher can publish tasks, the worker can take them into work, hand over the work, publisher can accept it or decline. When task publisher publish task he should send msg.value during call publishTask().
When worker send solution using passTask() and publisher accept it, worker receive msg.value-fee. 
Please, do nto use this version in production. There is UUPS version with DAO implementation for fee change.
Do not use this is production, this is first pet project just for memories.

Files:
- 00-Proxy.sol: Implementation of ERC1967Proxy by OZ;
- 01-Board.sol: Main contract;
- 02-PriceConsumerV3.sol: SC by ChainLink using for calc minimal price of published task (1% of eth);
- 03-MyERC20.sol: ERC20 using for DAO votes.
- 04-DAO.sol: Simple DAO using for with ERC20Votes module.


