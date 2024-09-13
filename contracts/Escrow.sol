//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint256 _id
    ) external;
}

contract Escrow {
    address public nftAddress;
    address payable public seller; // It's payable because he is going to receive crypto currency
    address public lender;
    address public inspector;

    modifier onlySeller() {
        require(msg.sender==seller,"Only Seller can call this method");
        _;
    }

    modifier onlyBuyer(uint256 _nftID){
        require(msg.sender == buyer[_nftID],"Only Buyer can call this method");
        _;
    }

    modifier onlyInspector(){
        require(msg.sender == inspector,"Only Inspector can call this method");
        _;
    }

    mapping(uint256=>bool) public isListed;
    mapping(uint256=>uint256) public purchasePrice;
    mapping(uint256=>uint256) public escrowAmount;
    mapping(uint256=>address) public buyer;
    mapping(uint256=>bool) public inspectionPassed;
    mapping(uint256=>mapping(address=>bool)) public approval;

    constructor(address _nftAddress, address payable _seller, address _inspector , address _lender){
        nftAddress = _nftAddress;
        seller = _seller;
        lender= _lender;
        inspector = _inspector;
    }

    function list(uint256 _nftID,address _buyer ,uint256 _purchasePrice,uint256 _escrowAmount) public payable onlySeller {
        //Transfer NFT from seller to this contact
        IERC721(nftAddress).transferFrom(msg.sender,address(this),_nftID);
        isListed[_nftID]=true;
        purchasePrice[_nftID]=_purchasePrice;
        escrowAmount[_nftID]=_escrowAmount;
        buyer[_nftID]=_buyer;
    }

    function depositEarnest(uint256 _nftID) public payable onlyBuyer(_nftID){
        require(msg.value>= escrowAmount[_nftID]);
    }

    function updateInspectionStatus(uint256 _nftID,bool _passed) public onlyInspector{
        inspectionPassed[_nftID]=_passed;
    }

    function approveSale(uint256 _nftID) public {
        approval[_nftID][msg.sender]=true;
    }

    receive() external payable{}

    function getBalance()public view returns(uint256){
        return address(this).balance;
    }

    function finalizeSale(uint256 _nftID) public {
        require(inspectionPassed[_nftID]);
        require(approval[_nftID][buyer[_nftID]]);
        require(approval[_nftID][seller]);
        require(approval[_nftID][lender]);
        require(address(this).balance >= purchasePrice[_nftID]);
    }
}
