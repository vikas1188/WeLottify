pragma solidity ^0.4.0;
// All the amount calculations shall be in WEI as internally Etherum keep them in WEI format only.

/*======================================Time line of events in the lottery pool======================================================*/
/*===================================================================================================================================*/
/*=====Pool=========================Cut-off========================Ticket===================================Draw==============Next===*/
/*===Creation========================Date========================Upload Date================================Date==============Pool===*/
/*===================================================================================================================================*/


contract WeLottify {
    
    uint256 poolId=1;
    uint256 totalCompletedPools;
    
    struct Pool{
        address leaderAddress;
        string poolName;
        string IPFSLinkOfTickets;
        bytes32 secretToken;//needed in case of the pool is unlisted
        uint256 poolPlayerLimit;
        uint256 totalMoneyPooled;
        uint256 NoOfPlayersJoined;
        uint256 feesToBeTakenByLeader;
        bool ended;
    }
    
    struct extendedPool{
        address leaderAddress;
        uint256 ticketCost;
        uint256 poolSequenceNo;//unique pool No to differentiate
        bool isUnlisted;
        bool isTicketUploaded;
        address[] playersJoinedInThisPool;
        uint256 LotteryPoolStartDate;
        uint256 LotteryPoolDrawDate;
        uint256 LotteryPoolCutOffDate;
        uint256 TicketImageUploadDate;
        bool canFetchManually;
        
    }
    
    struct PoolPlayer{
        uint256 joinedPoolId; // this is the poolId of the player that he joined
        bool isJoined;
        bool haveWithdrawn;
        //uint256 totalPoolJoinedByPlayer; //just to keep track how many pool this guys is a part of
    }
    
    struct ProfileInfo{
        address playerAddress;
        string name;
        string location;
    }
    
    modifier condition(bool _condition) {
        require(_condition);
        _;
    }
    modifier onlyBefore(uint _time) { 
        require(now < _time); 
        _; 
        
    }
    modifier onlyAfter(uint _time) { 
        require(now > _time); 
        _; 
        
    }

    mapping(uint256=>Pool) public pools;
    mapping(uint256=>extendedPool) public extendedpools;
    mapping(address=>PoolPlayer[]) public poolPlayers;
    mapping(address=>ProfileInfo) public profileDetails;
    // mapping(address=>)
    // mapping(uint256=>GroupOfPlayersInPool) public playersInAPool;
    
    
    event PoolCreated(address indexed leaderAddress, uint256 indexed poolPlayerLimit, uint256 indexed poolGlobalID, bool isUnlisted, bytes32 secretToken, uint256  drawDate);
    event UploadImage(address indexed leaderAddress, uint256 indexed poolPlayerLimit, uint256 indexed poolGlobalID);
    
    
    
     /**@dev Anyone can create a pool by passing some minimal no of parameters
     * @param _poolName Name of the pool e.g. Lucky Thirty, Mega forty etc
     * @param _poolPlayerLimit Upper limit on the no of player
     * @param _isUnlisted if this pool is private so unlisted from the search
     * @param _secretToken if the pool is private, then leader has to provide a secret token to the participants to join his private pool
     * @param _feesToBetakenByLeader upfront fees set by the leader to carry out the operation honestly and efficiently
     * @param _ticketCost this cost shall be actual ticket cost + small addition fee to compensate for the leader fees
     * @param _drawDate this is the draw date set by the leader for his pool
    */
    function createPool(string _poolName, uint256 _poolPlayerLimit, bool _isUnlisted,bytes32 _secretToken,  uint256 _feesToBetakenByLeader, uint256 _ticketCost,uint256 _drawDate){
        
        pools[poolId].leaderAddress = msg.sender;
        pools[poolId].poolName = _poolName;
        pools[poolId].poolPlayerLimit = _poolPlayerLimit;
        extendedpools[poolId].isUnlisted = _isUnlisted;
        pools[poolId].feesToBeTakenByLeader = _feesToBetakenByLeader;
        extendedpools[poolId].ticketCost = _ticketCost;
        pools[poolId].totalMoneyPooled = 0;
        pools[poolId].NoOfPlayersJoined = 0;
        extendedpools[poolId].LotteryPoolStartDate = now;
        extendedpools[poolId].LotteryPoolDrawDate = now + _drawDate;
        extendedpools[poolId].LotteryPoolCutOffDate =  extendedpools[poolId].LotteryPoolDrawDate - 2 days;
        extendedpools[poolId].TicketImageUploadDate = extendedpools[poolId].LotteryPoolCutOffDate + 1 days;
        pools[poolId].ended = false;
        if(extendedpools[poolId].isUnlisted) {
            pools[poolId].secretToken = _secretToken;
        }
        else{
            pools[poolId].secretToken = '';
        }
        PoolCreated(msg.sender, pools[poolId].poolPlayerLimit,poolId, extendedpools[poolId].isUnlisted,pools[poolId].secretToken, _drawDate );
        poolId++; 
    }
    
    /**@dev Anyone can join a pool created by anyone by paying the ticket fee + small additional fee
     * @param _poolId UniqueID of the pool of integer type. it shall start from 1 and keep on incrementing
     * @param _leaderAddress Address of the leader of this pool
     * @param _isJoiningUnlistedPool if this pool is private then true, otherwise false
     * @param _secretToken if the pool is private, then leader has to provide a secret token to the participants to join his private pool
     * @return string giving information what have happened when someone tried to join a pool . Multiple scenario can happen.e.g. he may be the first person to join the pool. 
     * & may be the last. if last then we have to tackle those cases
     * @modifiers some modifiers to keep a check that only valid data gets entered in the blockchain
    */
    function JoinPool(uint256 _poolId, address _leaderAddress ,bool _isJoiningUnlistedPool, bytes32 _secretToken)
    condition(msg.value >= (extendedpools[_poolId].ticketCost))
    condition(pools[_poolId].ended == false )
    onlyAfter(extendedpools[_poolId].LotteryPoolStartDate)
    onlyBefore(extendedpools[_poolId].LotteryPoolCutOffDate)
    payable
    returns (string)
    {
        if(pools[_poolId].NoOfPlayersJoined == pools[_poolId].poolPlayerLimit ) { //check that did we reached the limit or not
            return "Pool Player Limit reached";
        }
        else { //we are yet to reach the limit
            pools[_poolId].NoOfPlayersJoined++;
            
            if(_isJoiningUnlistedPool){
                if( pools[_poolId].secretToken == _secretToken){
                    // individual player information should get updated
                    poolPlayers[msg.sender].push(PoolPlayer({
                        joinedPoolId : _poolId ,
                        isJoined: true,
                        haveWithdrawn: false
                    })); // Length of this array shall be total no of the pools this guy have joined at any point of time.
                    
                    // the pool information should get updated.
                    extendedpools[_poolId].playersJoinedInThisPool[pools[_poolId].NoOfPlayersJoined-1] = msg.sender;
                    
                    //increase the money of the pool 
                    }
                else {
                    return "Wrong Secret provided. Get correct secret from the Group Leader";
                }
            }
            else {
                // to do : individual information should get updated
                poolPlayers[msg.sender].push(PoolPlayer({
                    joinedPoolId : _poolId,
                    isJoined: true,
                    haveWithdrawn: false
                })); // Length of this array shall be total no of the pools this guy have joined at any point of time.
                
                // the pool information should get updated.
                extendedpools[_poolId].playersJoinedInThisPool[pools[_poolId].NoOfPlayersJoined-1] = msg.sender;    
            }
            pools[_poolId].totalMoneyPooled += extendedpools[_poolId].ticketCost; // adding the total money cumulated in the smart contract from this pool
            
            if(pools[_poolId].NoOfPlayersJoined == pools[_poolId].poolPlayerLimit  ){
                var amount = pools[_poolId].totalMoneyPooled ;
                if (amount >= extendedpools[_poolId].ticketCost * pools[poolId].poolPlayerLimit){
                    pools[_poolId].totalMoneyPooled = 0;
                    bool isSendSuccess = _leaderAddress.send(amount);
                    if(isSendSuccess){ 
                        extendedpools[poolId].LotteryPoolCutOffDate = now ; // we're changing this because changing it will allow the leader to upload the ticket quickly.
                        UploadImage(_leaderAddress, pools[poolId].poolPlayerLimit,poolId); //this is the intimation to the leader to upload the ticket.
                    }
                    else {
                        
                       pools[_poolId].totalMoneyPooled = amount;
                       extendedpools[poolId].canFetchManually = true;
                       return "Total money is reached. But we faced some issue in transferring it to the Leader's Address. Try manually.";
                    }
                }
                else {
                    pools[_poolId].ended = true;
                    return "Total money is not reached with the set player limit. Hence giving back the money and ending this pool" ;
                    //to do: give back all the money of all the participants
                }
                
            }
            return "Player joined successfully";
        }
    }
    
    
    /**@dev After the total player limit is reached and the total amount gets collected in the smart contract, then leader has to upload the smart 
     * contract before the draw date and after the cut-off date. mentioned in the modifiers
     * @param _imageURLonIPFS Uniques Hash of the file uploaded on the IPFS. this shall contain the ticket images' URL that were uploaded on IPFS
     * @param _poolId UniqueID of the pool for which the leader has to upload these ticket images
     * @return bool keeping the flag for successful operation. returning true.
     * @modifiers some modifiers to keep a check that only valid data gets entered in the blockchain
    */
    function uploadTicketImages(string _imageURLonIPFS, uint256 _poolId)
    condition(msg.sender == (pools[_poolId].leaderAddress))
    onlyAfter(extendedpools[_poolId].LotteryPoolCutOffDate)
    onlyBefore(extendedpools[_poolId].TicketImageUploadDate)
    returns (bool)
    {
        pools[_poolId].IPFSLinkOfTickets = _imageURLonIPFS;
        return true;
    }
    
    /**@dev Ideally we shall have a script that shall fetch the list of the pools whose draw date is less than today's date and end those pool. So this method shall be used to end the pool externally or automatically
     * This can only be called after the draw date
     * @param _poolId UniqueID of the pool for which the leader has to upload these ticket images
     * @return bool keeping the flag for successful operation. returning true.
     * @modifiers some modifiers to keep a check that only valid data gets entered in the blockchain. 
    */
    function endPool(uint256 _poolId) 
    condition(msg.sender == (pools[_poolId].leaderAddress))
    condition(pools[_poolId].ended == false )
    onlyAfter(extendedpools[_poolId].LotteryPoolDrawDate)
    returns (bool)
    {
        pools[_poolId].ended = true;
        return true;
    }
    
    /**@dev Method to update the basic profile parameter. Name and location only. For simplicity sake we are keeping this much details only. 
     * In future, this can be extended with varifiable entity using uPort or some digital identity mechanism. These details can be blank as well, if the player wants to be anonymous. 
     * In that case only address is enough, just like Ethereum or bitcoin. No names or location.
     * @param _name Name of the participant
     * @param _location location of the participant
     * @return bool keeping the flag for successful operation. returning true.
    */
    function updateProfile (string _name, string _location) returns (bool){
        profileDetails[msg.sender].playerAddress = msg.sender;
        profileDetails[msg.sender].name = _name;
        profileDetails[msg.sender].location = _location;
        return true;
    }
    
    
    /**@dev To fetch the name and the location of the player as per his address
     * @param _address address of the participant
     * @return _name returns the name of the participant
     * @return  _location location of the participant
    */
    function getPlayerDetails(address _address) returns (string _name, string _location){
        return (profileDetails[_address].name, profileDetails[_address].location);
    }
    
    /**@dev To give his own address. Not needed just keeping for debugging purpose. sometimes metamask doesn't get injected and some random address gets passed'
     * @return  address address of the request maker
    */
    function myAddress() returns (address){
        return msg.sender;
    }
    
    
    
    /**@dev This method is the fail-safe mechanism, if while sending the Ethers automatically in the "JoinPool" function fails for reason because send may fail in Ethereum.
     * this is a manual trigger for sending the funds to leader once the threshold reaches to the player limit and funds are accumulated in smart contract.
     * @param _poolId UniqueID of the pool
     * @return string Help us identify what went wrong, again, if sends fail while sending the money manually.
    */
    function pullFundsManually(uint256 _poolId)
    condition(msg.sender == (pools[_poolId].leaderAddress))
    onlyAfter(extendedpools[_poolId].LotteryPoolStartDate)
    onlyBefore(extendedpools[_poolId].TicketImageUploadDate)
    condition(extendedpools[poolId].canFetchManually == true)
    returns (string)
    {
        var amount = pools[_poolId].totalMoneyPooled ;
        if (pools[_poolId].NoOfPlayersJoined == pools[_poolId].poolPlayerLimit  && amount >= extendedpools[_poolId].ticketCost * pools[poolId].poolPlayerLimit){
            bool isSendSuccess = pools[_poolId].leaderAddress.send(amount);
            if(isSendSuccess){ 
                extendedpools[poolId].LotteryPoolCutOffDate = now ; // we're changing this because changing it will allow the leader to upload the ticket quickly.
                UploadImage(pools[_poolId].leaderAddress, pools[poolId].poolPlayerLimit,poolId); //this is the intimation to the leader to upload the ticket.
            }
            return "Leader manually extracted the money from the pool.";
        }
        else {
            return "Somebody withdraw his participation due to which the money can't be extracted.Try when the money reached the threshold.";
        }
    }
    
    /**@dev Participant can withdraw from any game anytime. We shall return his money minus some fee for gas. as we can't pay for the gas. this may make the pool money less than the target amount.
     * @param _poolId UniqueID of the pool
     * @param _participantAddress
     * @modifiers Some modifiers to check that before getting out from the pool, some bare minimum conditions are met.
     * @return string Help us identify what went wrong, again, if sends fail while sending the money manually.
    */
    function WithdrawParticipation(uint256 _poolId, address _participantAddress) 
    onlyAfter(extendedpools[_poolId].LotteryPoolStartDate)
    onlyBefore(extendedpools[_poolId].LotteryPoolCutOffDate)
    condition(true == poolPlayers[_participantAddress][_poolId].isJoined)
    condition(false == poolPlayers[_participantAddress][_poolId].haveWithdrawn)
    returns (bool)
    {
        
        var amount = extendedpools[_poolId].ticketCost - 100000000000000000; // deducting only a small value for GAS. As otherwise this will be bourne by the contract, which we don't want
        pools[_poolId].totalMoneyPooled -= extendedpools[_poolId].ticketCost;
        pools[_poolId].NoOfPlayersJoined--; //pool is updated here
        poolPlayers[_participantAddress][_poolId].isJoined = false; // this pools gets delisted from his personal list of pools which he joined.
        bool isSendSuccess = _participantAddress.send(amount); //send the reduced amount on the participant's address
        if(isSendSuccess){
            poolPlayers[_participantAddress][_poolId].haveWithdrawn = true;
            return true;
        }
        else {
             poolPlayers[_participantAddress][_poolId].haveWithdrawn = false;
             return false;
        }
        
    }
}
    
  
