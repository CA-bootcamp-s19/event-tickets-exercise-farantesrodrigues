pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {
    address payable public owner;

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    uint PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint private idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an uinteger, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);
    event LogReadEvent(string description, string website, uint totalTickets, uint sales, bool isOpen);

    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier isOwner() {
        require(msg.sender == owner, 'sender is not owner');
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string memory _description, string memory _url, uint _ticketNumber)
        public isOwner
        returns(uint)
    {
        Event memory newEvent = Event({description: _description, website: _url, totalTickets: _ticketNumber, isOpen: true, sales: 0});
        uint newId = idGenerator;
        events[newId] = newEvent;

        emit LogEventAdded(_description, _url, _ticketNumber, newId);

        idGenerator++;
        return newId;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId)
        public view
        returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen)
    {
        return (
            events[_eventId].description,
            events[_eventId].website,
            events[_eventId].totalTickets,
            events[_eventId].sales,
            events[_eventId].isOpen
        );
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    // modifier eventIsOpened(uint _eventId) {
    //     require(events[_eventId].isOpen, 'event is closed');
    //     _;
    // }

    // modifier eventIsNotSoldOut(uint _eventId) {
    //     require(events[_eventId].totalTickets > 0, 'sold out');
    //     _;
    // }

    // modifier enoughValue(uint _numberOfTickets) {
    //     require((PRICE_TICKET * _numberOfTickets) <= msg.value, 'value not enough for transaction');
    //     _;
    // }

    function buyTickets(uint _eventId, uint _numberOfTickets)
        public
        payable
        returns(uint)
    {
        require(events[_eventId].isOpen == true, 'event is closed');
        require(msg.value >= _numberOfTickets * PRICE_TICKET, 'value not enough for transaction');
        require(events[_eventId].totalTickets - events[_eventId].sales >= _numberOfTickets, 'sold out');

        events[_eventId].buyers[msg.sender] += _numberOfTickets;
        events[_eventId].totalTickets -= _numberOfTickets;

        uint _amountToRefund = msg.value - (PRICE_TICKET * _numberOfTickets);
        if (_amountToRefund > 0) {
            address(msg.sender).transfer(_amountToRefund);
        }

        emit LogBuyTickets(msg.sender, _eventId, _numberOfTickets);

        return _numberOfTickets;
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId) public payable {
        require(events[_eventId].buyers[msg.sender] > 0, 'requester has no tickets');

        uint _amountToRefund = events[_eventId].buyers[msg.sender];

        uint _initialTotalTickets = events[_eventId].totalTickets;
        events[_eventId].totalTickets = _initialTotalTickets + _amountToRefund;

        uint _valueToRefund = PRICE_TICKET * _amountToRefund;
        msg.sender.transfer(_valueToRefund);

        emit LogGetRefund(msg.sender, _eventId, _amountToRefund);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId) public view returns(uint) {
        require(events[_eventId].buyers[msg.sender] > 0, 'requester has no tickets');

        uint _amountBought = events[_eventId].buyers[msg.sender];

        return _amountBought;
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId) public payable {
        events[_eventId].isOpen = false;
        uint balance = events[_eventId].totalTickets * PRICE_TICKET;
        owner.transfer(balance);
        emit LogEndSale(owner, balance, _eventId);
    }
}
