// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*A simple contract that allows interaction between the task publisher and the worker. 
The task publisher can publish tasks, the worker can take them into work, hand over the work, publisher can accept it or decline.
When task publisher publish task he should send msg.value during call publishTask().
When worker send solution using passTask() and publisher accept it, worker receive msg.value-fee.
*/

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./02-PriceConsumerV3.sol";

contract Board is Initializable, UUPSUpgradeable, OwnableUpgradeable, PriceConsumerV3 {
    
    modifier onlyDAO() {
        require (msg.sender == DAO);
        _;
    }
    
    event PublishTask (uint256 id, string taskName, uint256 price);
    event CancelPublishedTask (uint256 id, string taskName, uint256 price);
    event GetTask (uint256 id, string taskName, address publisher, address worker);
    event PassTask (uint256 id, string taskName, address publisher, address worker);
    event ApproveTask (uint256 id, string taskName, address publisher, address worker);
    event FeeChanged (uint256 oldFee, uint256 newFee);
    event OracleAddressChanged (address oldOracleAddress, address newOraclePrice);

    address public DAO;
    address public oracle;
    uint256 public fee;
    
    //@note you are free to set onlyDAO/onlyOwner modificator here. Do not use w/o it.
    function changeFee(uint256 _fee) external {
        uint256 oldFee = fee;
        fee = _fee;

        emit FeeChanged (oldFee, _fee);  
    }

    //@note 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e current ChainkLink eth price SC.
    function changeOracleAddress(address _oracle) external onlyDAO {
        address oldOracle = oracle;
        oracle = _oracle;

        emit OracleAddressChanged (oldOracle, oracle);  
    }

    //@note for proxy versions
    function initialize(uint256 _fee, address _dao) public initializer {
        __Ownable_init();
        require(_fee >=0 && _fee <= 25);
        fee = _fee;
        DAO =_dao;
        oracle = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
  
    enum TaskStatuses { Published, atWork, waitingForApproval, Approved } 
    TaskStatuses currentTaskStatus;

    struct Task {
        TaskStatuses currentTaskStatus;
        address publisherAddress;
        string taskName;
        string linkAtTaskDescription;
        address workerAddress;
        uint256 price;
        uint256 totalFee;
        bool payed;
    }

    Task[] public arrayTasks;
        
    //@note Anyone can publish task with msg.value;    
    function publishTask(string calldata _taskName, string calldata _linkAtTaskDescription) external payable {
        require(msg.value > minimumPrice(),"Less than minimum price"); 
        arrayTasks.push(Task({
            currentTaskStatus: TaskStatuses.Published,
            publisherAddress: msg.sender,
            taskName: _taskName,
            linkAtTaskDescription: _linkAtTaskDescription,
            workerAddress: 0x0000000000000000000000000000000000000000,
            price: msg.value - msg.value * fee / 100,
            totalFee: msg.value * fee / 100,
            payed: false
        }));

        emit PublishTask (arrayTasks.length, _taskName, arrayTasks[arrayTasks.length-1].price); 
    }

    //@note 1% from chainLinkFeedPriceEth;
    function minimumPrice() public view returns(uint256)  {
        return uint256(PriceConsumerV3.getLatestPrice()*10**7/100); //what to do if chainlink contract died
    }

    //@note publisher can cancel if no one got it to work.
    function cancelPublishedTask(uint256 _taskId) external {
        require(arrayTasks[_taskId].publisherAddress == tx.origin,"You are not allowed to cancel it");
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.Published,"Can't cancel in this status");
        delete arrayTasks[_taskId];

        emit CancelPublishedTask (_taskId, arrayTasks[_taskId].taskName, arrayTasks[_taskId].price);
    }

    //@note worker can get task.
    function getTask(uint256 _taskId) external { 
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.Published,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.atWork;
        arrayTasks[_taskId].workerAddress = tx.origin;

        emit GetTask (_taskId, arrayTasks[_taskId].taskName, arrayTasks[_taskId].publisherAddress, arrayTasks[_taskId].workerAddress);
    }

    //@note worker can pass task.
    function passTask(uint256 _taskId) external {
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.atWork,"Can't take task in this status");
        require(arrayTasks[_taskId].workerAddress == tx.origin,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.waitingForApproval;

        emit PassTask (_taskId, arrayTasks[_taskId].taskName, arrayTasks[_taskId].publisherAddress, arrayTasks[_taskId].workerAddress);
    }
    
    //@note If task has been passed by worker, you as a publisher of this task can approve it.
    function approveTask(uint256 _taskId) external {
        require(arrayTasks[_taskId].currentTaskStatus == TaskStatuses.waitingForApproval,"Can't take task in this status");
        require(arrayTasks[_taskId].publisherAddress ==  tx.origin,"Can't take task in this status");
        arrayTasks[_taskId].currentTaskStatus = TaskStatuses.Approved;
        
        require(arrayTasks[_taskId].payed == false,"Re-entrant guard");
        arrayTasks[_taskId].payed = true;

        (bool result, ) = arrayTasks[_taskId].workerAddress.call{value:arrayTasks[_taskId].price}(""); 
        require(result,"Seems receiver can't receive eth");

        emit ApproveTask (_taskId, arrayTasks[_taskId].taskName, arrayTasks[_taskId].publisherAddress, arrayTasks[_taskId].workerAddress);
    }

    //@note you are free to set onlyDAO/onlyOwner modificator here. Do not use w/o it.
    function withdraw(address target, uint256 amount) external {
        require(amount <= address(this).balance);
        bool payed;
        require(!payed,"No ree");
        payed = true;
        (bool result, ) = target.call{value:amount}(""); 
        require(result,"Unsuccessful withdraw");
    }

}


