pragma solidity ^0.5.0;

contract crowdsale {
    address public beneficiary;
    uint public fundingGoal;
    uint public fundingGoalInEthers = 1 ether;
    uint public amountRaised;
    uint public deadline;
    uint public durationInMinutes = 1 minutes;
    uint public price;
    uint public etherCostOfEachToken = 1 ether;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContributed);

    modifier afterDeadline() {
        if(now >= deadline)
        _;
    }
    //constructor
    constructor(
        address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
        uint durationInMinutes,
        uint etherCostOfEachToken,
        address addressOfTokenUsedAsReward
    ) public {
        beneficiary = ifSuccessfulSendTo;
        fundingGoal = fundingGoalInEthers;
        deadline = now + durationInMinutes;
        price = etherCostOfEachToken;
    }

    //Fullback function
    //called whenever anyone sends funds to the contract
    function () payable public {
        require(!crowdsaleClosed);
        uint amount = msg.value;
        balanceOf[msg.sender] += amount;
        amountRaised += amount;
        tokenReward.transfer(msg.sender, amount / price);
        emit FundTransfer(msg.sender, amount, true)
    }

    //check if goal was reached
    //check if the goal or time limit has been reached and ends the campaign
    
    function checkGoalReached() public afterDeadline{
        if(amountRaised >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

    //Withdrawal the funds

    //check to see if goal or the time limit has been reached 
    //if so, send the entire amount to the beneficiary
    //if not, each contributor can withdraw the amount they contributed
    function safeWithdrawal() public afterDeadline {
        if(!fundingGoalReached){
            uint amount = balanceOf[msg.sender];
            balanceOf[msg.sender] = 0;
            if(amount > 0){
                if(msg.sender.send(amount)){
                    emit FundTransfer(msg.sender, amount, false);
                } else {
                    balanceOf[msg.sender] = amount;
                }
            }
        }
        if (fundingGoalReached && beneficiary == msg.sender) {
            if(beneficiary.send(amountRaised)) {
                emit FundTransfer(beneficiary, amountRaised, false);
            } else {
                //if we fail to send the funds to the beneficiary, unlock funders balance
                fundingGoalReached = false;
            }
        }
    }
}